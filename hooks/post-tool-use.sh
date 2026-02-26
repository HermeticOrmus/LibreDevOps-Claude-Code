#!/bin/bash
# =============================================================================
# LibreDevOps Post Tool Use Hook
# =============================================================================
# Runs AFTER Edit/Write/MultiEdit operations on infrastructure files.
# Performs drift detection, compliance checking, and post-operation validation.
#
# What this hook does:
# 1. Validates Terraform files (format, secrets, state, security, encryption, tags)
# 2. Validates Kubernetes manifests (secrets, privileges, resources, probes, RBAC)
# 3. Validates Dockerfiles (root user, pinned images, secrets, health checks)
# 4. Validates CI/CD pipelines (tokens, pinning, permissions, timeouts)
# 5. Validates Docker Compose (resource limits, passwords, exposed ports)
# 6. Validates Ansible files (plaintext credentials)
# 7. Generic secret detection across all file types
# 8. Gitignore integrity check
# =============================================================================

set -euo pipefail

# Read hook input from stdin
HOOK_INPUT=$(cat)

# Extract tool name and file path
TOOL_NAME=$(echo "$HOOK_INPUT" | grep -oP '"tool_name"\s*:\s*"\K[^"]+' 2>/dev/null || echo "")
FILE_PATH=$(echo "$HOOK_INPUT" | grep -oP '"file_path"\s*:\s*"\K[^"]+' 2>/dev/null || echo "")

# Alternative extraction
if [ -z "$TOOL_NAME" ]; then
    TOOL_NAME=$(echo "$HOOK_INPUT" | grep -o '"tool_name":"[^"]*"' | cut -d'"' -f4 2>/dev/null || echo "")
fi
if [ -z "$FILE_PATH" ]; then
    FILE_PATH=$(echo "$HOOK_INPUT" | grep -o '"file_path":"[^"]*"' | cut -d'"' -f4 2>/dev/null || echo "")
fi

# Exit early if not a file modification tool
if [ "$TOOL_NAME" != "Edit" ] && [ "$TOOL_NAME" != "Write" ] && [ "$TOOL_NAME" != "MultiEdit" ]; then
    exit 0
fi

if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
    exit 0
fi

# Initialize arrays
WARNINGS=()

# Get file info
FILE_NAME=$(basename "$FILE_PATH")
FILE_DIR=$(dirname "$FILE_PATH")
FILE_EXT="${FILE_PATH##*.}"
FILE_NAME_LOWER=$(echo "$FILE_NAME" | tr '[:upper:]' '[:lower:]')
FILE_PATH_LOWER=$(echo "$FILE_PATH" | tr '[:upper:]' '[:lower:]')
FILE_CONTENT=$(cat "$FILE_PATH" 2>/dev/null || echo "")

# =============================================================================
# TERRAFORM POST-CHECKS
# =============================================================================

if echo "$FILE_EXT" | grep -qiE "^(tf|tfvars)$"; then

    # Check formatting
    if command -v terraform &>/dev/null; then
        if ! terraform fmt -check "$FILE_PATH" &>/dev/null 2>&1; then
            WARNINGS+=("TERRAFORM FORMAT: File not formatted. Run 'terraform fmt $FILE_PATH'.")
        fi
    fi

    # Hardcoded secrets in Terraform
    if echo "$FILE_CONTENT" | grep -qE '(password|secret|token|api_key)\s*=\s*"[^${}][^"]{4,}"' 2>/dev/null; then
        WARNINGS+=("TERRAFORM SECRETS: Possible hardcoded secret detected. Use variable references to a secret manager (aws_secretsmanager_secret, google_secret_manager_secret, azurerm_key_vault_secret).")
    fi

    # Missing state backend in directories with resources
    if echo "$FILE_EXT" | grep -qiE "^tf$"; then
        TF_DIR="$FILE_DIR"
        if ls "$TF_DIR"/*.tf &>/dev/null 2>&1; then
            if ! grep -rl 'backend "' "$TF_DIR" --include="*.tf" &>/dev/null 2>&1; then
                if grep -rl 'resource "' "$TF_DIR" --include="*.tf" &>/dev/null 2>&1; then
                    WARNINGS+=("TERRAFORM STATE: No remote state backend configured in $TF_DIR. Add a backend block (S3, GCS, Azure Blob) with encryption and locking.")
                fi
            fi
        fi
    fi

    # Overly permissive security groups (0.0.0.0/0 ingress)
    if echo "$FILE_CONTENT" | grep -qE 'cidr_blocks\s*=\s*\["0\.0\.0\.0/0"\]' 2>/dev/null; then
        if echo "$FILE_CONTENT" | grep -qE 'ingress|inbound' 2>/dev/null; then
            WARNINGS+=("TERRAFORM SECURITY: Security group allows ingress from 0.0.0.0/0. Restrict to specific CIDR blocks unless this is a public load balancer on ports 80/443.")
        fi
    fi
    if echo "$FILE_CONTENT" | grep -qE 'source_address_prefix\s*=\s*"\*"' 2>/dev/null; then
        WARNINGS+=("TERRAFORM SECURITY: Azure NSG allows traffic from any source (*). Restrict to specific address prefixes.")
    fi
    if echo "$FILE_CONTENT" | grep -qE 'source_ranges\s*=\s*\["0\.0\.0\.0/0"\]' 2>/dev/null; then
        WARNINGS+=("TERRAFORM SECURITY: GCP firewall allows traffic from 0.0.0.0/0. Restrict source ranges.")
    fi

    # Missing encryption
    if echo "$FILE_CONTENT" | grep -qE 'aws_s3_bucket\b' 2>/dev/null; then
        if ! echo "$FILE_CONTENT" | grep -qE 'server_side_encryption_configuration|aws_s3_bucket_server_side_encryption' 2>/dev/null; then
            WARNINGS+=("TERRAFORM ENCRYPTION: S3 bucket without explicit encryption configuration. Add server_side_encryption_configuration or use aws_s3_bucket_server_side_encryption_configuration resource.")
        fi
    fi
    if echo "$FILE_CONTENT" | grep -qE 'aws_db_instance|aws_rds_cluster' 2>/dev/null; then
        if ! echo "$FILE_CONTENT" | grep -q 'storage_encrypted' 2>/dev/null; then
            WARNINGS+=("TERRAFORM ENCRYPTION: RDS instance without storage_encrypted = true. Enable encryption at rest.")
        fi
    fi
    if echo "$FILE_CONTENT" | grep -qE 'aws_ebs_volume' 2>/dev/null; then
        if ! echo "$FILE_CONTENT" | grep -q 'encrypted' 2>/dev/null; then
            WARNINGS+=("TERRAFORM ENCRYPTION: EBS volume without encryption. Set encrypted = true.")
        fi
    fi

    # Wildcard IAM
    if echo "$FILE_CONTENT" | grep -qE '"actions"\s*:\s*\["\*"\]|actions\s*=\s*\["\*"\]|"Action"\s*:\s*"\*"' 2>/dev/null; then
        WARNINGS+=("TERRAFORM IAM: Wildcard (*) actions detected in IAM policy. Follow principle of least privilege -- grant only specific actions needed.")
    fi
    if echo "$FILE_CONTENT" | grep -qE '"resources"\s*:\s*\["\*"\]|resources\s*=\s*\["\*"\]|"Resource"\s*:\s*"\*"' 2>/dev/null; then
        WARNINGS+=("TERRAFORM IAM: Wildcard (*) resources detected in IAM policy. Scope to specific resource ARNs.")
    fi

    # Public databases
    if echo "$FILE_CONTENT" | grep -qE 'publicly_accessible\s*=\s*true' 2>/dev/null; then
        WARNINGS+=("TERRAFORM SECURITY: Database set to publicly_accessible = true. Databases should be in private subnets, accessed through bastion hosts or VPN.")
    fi

    # IMDSv1 (prefer v2)
    if echo "$FILE_CONTENT" | grep -qE 'aws_instance|aws_launch_template' 2>/dev/null; then
        if ! echo "$FILE_CONTENT" | grep -q 'http_tokens' 2>/dev/null; then
            WARNINGS+=("TERRAFORM SECURITY: EC2 instance without IMDSv2 enforcement. Add metadata_options { http_tokens = \"required\" } to prevent SSRF-based credential theft.")
        fi
    fi

    # Missing tags on AWS resources
    if echo "$FILE_CONTENT" | grep -qE 'resource "aws_' 2>/dev/null; then
        if ! echo "$FILE_CONTENT" | grep -q 'tags' 2>/dev/null; then
            WARNINGS+=("TERRAFORM TAGS: AWS resources without tags. Add tags for cost tracking, ownership, and environment identification (Project, Environment, ManagedBy).")
        fi
    fi

    # Unversioned providers
    if echo "$FILE_CONTENT" | grep -qE 'required_providers' 2>/dev/null; then
        if echo "$FILE_CONTENT" | grep -qE 'version\s*=\s*">=' 2>/dev/null; then
            WARNINGS+=("TERRAFORM PROVIDERS: Provider version uses >= constraint. Pin to exact version (version = \"x.y.z\") or use ~> for patch-level flexibility to prevent unexpected changes.")
        fi
    fi
fi

# =============================================================================
# KUBERNETES POST-CHECKS
# =============================================================================

IS_K8S=false

if echo "$FILE_PATH_LOWER" | grep -qE "/(k8s|kubernetes|manifests|charts|helm|deploy)/" 2>/dev/null; then
    if echo "$FILE_EXT" | grep -qiE "^(yaml|yml|json)$"; then
        IS_K8S=true
    fi
fi

# Also detect K8s by content
if [ "$IS_K8S" = false ] && echo "$FILE_EXT" | grep -qiE "^(yaml|yml)$"; then
    if echo "$FILE_CONTENT" | grep -qE "^kind:\s+(Deployment|Service|Pod|StatefulSet|DaemonSet|Job|CronJob|Ingress|ConfigMap|Secret|Namespace)" 2>/dev/null; then
        IS_K8S=true
    fi
fi

if [ "$IS_K8S" = true ]; then

    # Plain-text secrets (base64 is NOT encryption)
    if echo "$FILE_CONTENT" | grep -q "kind: Secret" 2>/dev/null; then
        WARNINGS+=("K8S SECRETS: Kubernetes Secret written. Base64 encoding is NOT encryption. Use External Secrets Operator, Sealed Secrets, or mount from a secret manager (Vault, AWS Secrets Manager).")
    fi

    # Privileged containers
    if echo "$FILE_CONTENT" | grep -q "privileged: true" 2>/dev/null; then
        WARNINGS+=("K8S SECURITY: Privileged container detected. This grants full host access. Remove unless absolutely required (e.g., CNI plugin, storage driver).")
    fi

    # Host networking
    if echo "$FILE_CONTENT" | grep -q "hostNetwork: true" 2>/dev/null; then
        WARNINGS+=("K8S SECURITY: hostNetwork enabled. Container shares the node's network namespace. This bypasses network policies.")
    fi

    # Host PID namespace
    if echo "$FILE_CONTENT" | grep -q "hostPID: true" 2>/dev/null; then
        WARNINGS+=("K8S SECURITY: hostPID enabled. Container can see all processes on the node. This is a privilege escalation risk.")
    fi

    # Missing resource limits on Deployments
    if echo "$FILE_CONTENT" | grep -qE "kind:\s*(Deployment|StatefulSet|DaemonSet)" 2>/dev/null; then
        if ! echo "$FILE_CONTENT" | grep -q "resources:" 2>/dev/null; then
            WARNINGS+=("K8S RESOURCES: Workload without resource limits. Add requests and limits for CPU and memory to prevent noisy-neighbor problems and OOM kills.")
        fi
    fi

    # Missing health probes
    if echo "$FILE_CONTENT" | grep -qE "kind:\s*(Deployment|StatefulSet)" 2>/dev/null; then
        if ! echo "$FILE_CONTENT" | grep -qE "readinessProbe:|livenessProbe:" 2>/dev/null; then
            WARNINGS+=("K8S PROBES: Workload without health probes. Add readinessProbe (traffic routing) and livenessProbe (restart policy) for reliable rollouts.")
        fi
    fi

    # Running as root
    if echo "$FILE_CONTENT" | grep -q "runAsNonRoot: false" 2>/dev/null; then
        WARNINGS+=("K8S SECURITY: Container explicitly set to run as root (runAsNonRoot: false). Set runAsNonRoot: true and specify a non-root runAsUser.")
    fi

    # Latest tag
    if echo "$FILE_CONTENT" | grep -qE "image:.*:latest" 2>/dev/null; then
        WARNINGS+=("K8S IMAGES: Container uses ':latest' tag. Pin to a specific version or SHA digest for reproducible deployments and safe rollbacks.")
    fi

    # Single replica
    if echo "$FILE_CONTENT" | grep -qE "replicas:\s*1$" 2>/dev/null; then
        if echo "$FILE_CONTENT" | grep -q "kind: Deployment" 2>/dev/null; then
            WARNINGS+=("K8S AVAILABILITY: Deployment has 1 replica. Consider multiple replicas with a PodDisruptionBudget for high availability.")
        fi
    fi

    # RBAC with cluster-admin
    if echo "$FILE_CONTENT" | grep -qE "cluster-admin" 2>/dev/null; then
        WARNINGS+=("K8S RBAC: cluster-admin role binding detected. This grants unrestricted cluster access. Use scoped roles with minimum necessary permissions.")
    fi
fi

# =============================================================================
# DOCKERFILE POST-CHECKS
# =============================================================================

if echo "$FILE_NAME_LOWER" | grep -qE "^dockerfile"; then

    # Running as root (no USER instruction)
    if ! echo "$FILE_CONTENT" | grep -q "^USER " 2>/dev/null; then
        WARNINGS+=("DOCKER SECURITY: No USER instruction. Container runs as root by default. Add 'USER nonroot' or 'USER 1000' after installing packages.")
    fi

    # Unpinned base image
    if echo "$FILE_CONTENT" | grep -qE "^FROM .+:latest" 2>/dev/null; then
        WARNINGS+=("DOCKER IMAGES: Base image uses ':latest' tag. Pin to a specific version (e.g., node:22.2.0-alpine) for reproducible builds.")
    fi
    if echo "$FILE_CONTENT" | grep -qE "^FROM [a-z]+$" 2>/dev/null; then
        WARNINGS+=("DOCKER IMAGES: Base image has no tag at all (implies :latest). Pin to a specific version.")
    fi

    # Secrets copied into image
    if echo "$FILE_CONTENT" | grep -qE "^(COPY|ADD)\s+.*\.(env|pem|key|cert|p12|pfx|jks)" 2>/dev/null; then
        WARNINGS+=("DOCKER SECRETS: Secret or key file copied into image layer. Use Docker secrets, BuildKit secret mounts (--mount=type=secret), or multi-stage builds.")
    fi

    # ADD with URL (prefer COPY + curl for caching and verification)
    if echo "$FILE_CONTENT" | grep -qE "^ADD\s+https?://" 2>/dev/null; then
        WARNINGS+=("DOCKER BEST PRACTICE: ADD with URL detected. Use COPY with a prior RUN curl/wget step for better caching and checksum verification.")
    fi

    # No HEALTHCHECK
    if ! echo "$FILE_CONTENT" | grep -q "^HEALTHCHECK" 2>/dev/null; then
        WARNINGS+=("DOCKER HEALTH: No HEALTHCHECK instruction. Add HEALTHCHECK to enable container health monitoring by orchestrators.")
    fi

    # npm install instead of npm ci
    if echo "$FILE_CONTENT" | grep -qE "npm install" 2>/dev/null; then
        if ! echo "$FILE_CONTENT" | grep -qE "npm ci" 2>/dev/null; then
            WARNINGS+=("DOCKER NODE: Uses 'npm install' instead of 'npm ci'. Use 'npm ci' in Dockerfiles for deterministic, faster installs from lockfile.")
        fi
    fi

    # No .dockerignore
    if [ ! -f "$FILE_DIR/.dockerignore" ]; then
        WARNINGS+=("DOCKER BUILD: No .dockerignore file found alongside Dockerfile. Create one to exclude .git, node_modules, .env files, and other build context bloat.")
    fi

    # Secrets in build args
    if echo "$FILE_CONTENT" | grep -qiE "ARG.*(password|secret|token|key|credential)" 2>/dev/null; then
        WARNINGS+=("DOCKER SECRETS: Build ARG may contain secrets. ARG values are visible in image history (docker history). Use BuildKit secret mounts instead.")
    fi
fi

# =============================================================================
# CI/CD POST-CHECKS
# =============================================================================

IS_CI=false

if echo "$FILE_PATH_LOWER" | grep -qE "/(\.github/workflows|\.circleci|\.buildkite)/" 2>/dev/null; then
    IS_CI=true
fi
if echo "$FILE_NAME_LOWER" | grep -qE "^(jenkinsfile|\.gitlab-ci\.yml|\.travis\.yml|azure-pipelines\.yml|bitbucket-pipelines\.yml|\.drone\.yml)$" 2>/dev/null; then
    IS_CI=true
fi

if [ "$IS_CI" = true ]; then

    # Hardcoded tokens
    if echo "$FILE_CONTENT" | grep -qE "(ghp_|gho_|github_pat_)[a-zA-Z0-9]{20,}" 2>/dev/null; then
        WARNINGS+=("CI/CD CRITICAL: GitHub token detected in pipeline config. Remove immediately and rotate the token. Use repository secrets.")
    fi
    if echo "$FILE_CONTENT" | grep -qE "glpat-[a-zA-Z0-9]{20,}" 2>/dev/null; then
        WARNINGS+=("CI/CD CRITICAL: GitLab personal access token detected. Remove and use CI/CD variables.")
    fi
    if echo "$FILE_CONTENT" | grep -qE "AKIA[A-Z0-9]{16}" 2>/dev/null; then
        WARNINGS+=("CI/CD CRITICAL: AWS access key detected. Remove and use OIDC federation or repository secrets.")
    fi

    # Unpinned GitHub Actions
    if echo "$FILE_CONTENT" | grep -qE "uses:\s+\S+@(main|master|latest)" 2>/dev/null; then
        WARNINGS+=("CI/CD SUPPLY CHAIN: GitHub Actions pinned to branch names (main/master/latest). Pin to commit SHA for supply chain security.")
    fi
    if echo "$FILE_CONTENT" | grep -qE "uses:\s+\S+@v[0-9]+$" 2>/dev/null; then
        WARNINGS+=("CI/CD SUPPLY CHAIN: GitHub Actions pinned to major version tag (e.g., @v4). Pin to full commit SHA with a version comment for supply chain security.")
    fi

    # Secret exposure in echo/print
    if echo "$FILE_CONTENT" | grep -qiE "echo.*\\\$\{?\{?secrets\." 2>/dev/null; then
        WARNINGS+=("CI/CD SECRETS: Possible secret exposure via echo/print. Never log secret values. GitHub masks known secrets but custom values may leak.")
    fi

    # Overly permissive permissions
    if echo "$FILE_CONTENT" | grep -qE "permissions:\s*write-all" 2>/dev/null; then
        WARNINGS+=("CI/CD PERMISSIONS: write-all permissions detected. Use granular permissions (contents: read, packages: write, etc.) following principle of least privilege.")
    fi

    # Missing permissions block (GitHub Actions)
    if echo "$FILE_PATH_LOWER" | grep -qE "\.github/workflows/" 2>/dev/null; then
        if ! echo "$FILE_CONTENT" | grep -q "permissions:" 2>/dev/null; then
            WARNINGS+=("CI/CD PERMISSIONS: No explicit permissions block. Add top-level permissions to restrict the GITHUB_TOKEN scope.")
        fi
        if ! echo "$FILE_CONTENT" | grep -q "timeout-minutes:" 2>/dev/null; then
            WARNINGS+=("CI/CD TIMEOUT: No timeout-minutes set. Add timeout to prevent hung workflows from consuming runner minutes.")
        fi
    fi
fi

# =============================================================================
# DOCKER COMPOSE POST-CHECKS
# =============================================================================

if echo "$FILE_NAME_LOWER" | grep -qE "^(docker-compose|compose)"; then

    # Missing resource limits
    if echo "$FILE_CONTENT" | grep -q "services:" 2>/dev/null; then
        if ! echo "$FILE_CONTENT" | grep -qE "mem_limit|deploy:" 2>/dev/null; then
            WARNINGS+=("COMPOSE RESOURCES: No memory limits configured. Add mem_limit or deploy.resources.limits to prevent containers from consuming all host memory.")
        fi
    fi

    # Hardcoded passwords
    if echo "$FILE_CONTENT" | grep -qiE "(MYSQL_ROOT_PASSWORD|POSTGRES_PASSWORD|MONGO_INITDB_ROOT_PASSWORD|REDIS_PASSWORD):\s*[a-zA-Z0-9]" 2>/dev/null; then
        WARNINGS+=("COMPOSE SECRETS: Hardcoded database password in Compose file. Use environment variables from .env file or Docker secrets.")
    fi

    # Exposed database ports to host
    if echo "$FILE_CONTENT" | grep -qE "ports:.*\b(3306|5432|27017|6379|9200)\b" 2>/dev/null; then
        WARNINGS+=("COMPOSE NETWORKING: Database port exposed to host. Remove host port mapping for databases -- access through application network only.")
    fi

    # Latest tags in compose
    if echo "$FILE_CONTENT" | grep -qE "image:.*:latest" 2>/dev/null; then
        WARNINGS+=("COMPOSE IMAGES: Service uses ':latest' tag. Pin to a specific version for reproducible deployments.")
    fi
fi

# =============================================================================
# ANSIBLE POST-CHECKS
# =============================================================================

if echo "$FILE_PATH_LOWER" | grep -qE "/(playbooks|roles|inventory|group_vars|host_vars)/" 2>/dev/null; then

    # Plaintext passwords
    if echo "$FILE_CONTENT" | grep -qE "ansible_become_password|ansible_ssh_pass|ansible_password" 2>/dev/null; then
        WARNINGS+=("ANSIBLE SECRETS: Plaintext credentials detected. Encrypt with 'ansible-vault encrypt_string' or use Ansible Vault files.")
    fi

    # Plaintext in variables
    if echo "$FILE_CONTENT" | grep -qiE "(password|secret|token|api_key):\s*[a-zA-Z0-9\"'][^{]" 2>/dev/null; then
        if ! echo "$FILE_CONTENT" | grep -q '!vault' 2>/dev/null; then
            WARNINGS+=("ANSIBLE SECRETS: Possible plaintext secret in variable file. Use ansible-vault to encrypt sensitive values.")
        fi
    fi
fi

# =============================================================================
# ENVIRONMENT FILE CHECKS
# =============================================================================

if echo "$FILE_NAME_LOWER" | grep -qE "^\.env|\.env\.|env\.local|env\.production|env\.staging"; then

    # Real values in environment files (not placeholders)
    if echo "$FILE_CONTENT" | grep -qE "(AKIA|ghp_|gho_|sk-|sk_live_|rk_live_|glpat-)" 2>/dev/null; then
        WARNINGS+=("ENV CRITICAL: Real credential detected in environment file. This file must NEVER be committed. Verify .gitignore includes this file.")
    fi
fi

# =============================================================================
# GENERIC SECRET DETECTION (ALL FILE TYPES)
# =============================================================================

# AWS Access Keys
if echo "$FILE_CONTENT" | grep -qE "AKIA[A-Z0-9]{16}" 2>/dev/null; then
    if [ "$IS_CI" = false ]; then
        WARNINGS+=("SECRET DETECTED: AWS access key ID pattern (AKIA...) found. Remove and use IAM roles, instance profiles, or OIDC federation.")
    fi
fi

# GitHub tokens
if echo "$FILE_CONTENT" | grep -qE "(ghp_|gho_|github_pat_)[a-zA-Z0-9]{20,}" 2>/dev/null; then
    if [ "$IS_CI" = false ]; then
        WARNINGS+=("SECRET DETECTED: GitHub token pattern found. Remove and use GITHUB_TOKEN or deploy keys.")
    fi
fi

# Private keys
if echo "$FILE_CONTENT" | grep -q "BEGIN.*PRIVATE KEY" 2>/dev/null; then
    WARNINGS+=("SECRET DETECTED: Private key found in file. Private keys must never be stored in code. Use a secret manager or certificate store.")
fi

# Database connection strings with passwords
if echo "$FILE_CONTENT" | grep -qiE "(mysql|postgres|mongodb|redis)://[^:]+:[^@]+@" 2>/dev/null; then
    WARNINGS+=("SECRET DETECTED: Database connection string with embedded password. Use environment variables or secret manager references.")
fi

# Stripe keys
if echo "$FILE_CONTENT" | grep -qE "(sk_live_|rk_live_|pk_live_)[a-zA-Z0-9]+" 2>/dev/null; then
    WARNINGS+=("SECRET DETECTED: Stripe live key found. Remove and use environment variables. Never commit live payment keys.")
fi

# =============================================================================
# GITIGNORE INTEGRITY CHECK
# =============================================================================

PROJECT_ROOT=$(git -C "$FILE_DIR" rev-parse --show-toplevel 2>/dev/null || echo "")
if [ -n "$PROJECT_ROOT" ] && [ -f "$PROJECT_ROOT/.gitignore" ]; then
    GITIGNORE_CONTENT=$(cat "$PROJECT_ROOT/.gitignore" 2>/dev/null || echo "")

    if ! echo "$GITIGNORE_CONTENT" | grep -q '\.env' 2>/dev/null; then
        WARNINGS+=("GITIGNORE: Missing .env exclusion. Add '.env*' to .gitignore to prevent accidental secret commits.")
    fi
    if ! echo "$GITIGNORE_CONTENT" | grep -q '\.tfstate' 2>/dev/null; then
        # Only warn if there are Terraform files in the project
        if ls "$PROJECT_ROOT"/*.tf &>/dev/null 2>&1 || find "$PROJECT_ROOT" -name "*.tf" -maxdepth 3 2>/dev/null | head -1 | grep -q .; then
            WARNINGS+=("GITIGNORE: Missing .tfstate exclusion. Add '*.tfstate' and '*.tfstate.*' to .gitignore.")
        fi
    fi
fi

# =============================================================================
# OUTPUT STRUCTURED RESPONSE
# =============================================================================

if [ ${#WARNINGS[@]} -gt 0 ]; then
    OUTPUT="{\"systemMessage\":\"LibreDevOps Post-Edit Infrastructure Scan:\\n"
    for warn in "${WARNINGS[@]}"; do
        ESCAPED_WARN=$(echo "$warn" | sed 's/"/\\"/g')
        OUTPUT="$OUTPUT- $ESCAPED_WARN\\n"
    done
    OUTPUT="$OUTPUT\"}"
    echo "$OUTPUT"
fi

exit 0
