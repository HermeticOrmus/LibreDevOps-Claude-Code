#!/bin/bash
# =============================================================================
# LibreDevOps Pre Tool Use Hook
# =============================================================================
# Runs BEFORE Edit/Write/MultiEdit operations on infrastructure files.
# Detects what kind of infrastructure file is being modified and provides
# safety guidance. Blocks direct modification of state and credential files.
#
# What this hook does:
# 1. Blocks modification of Terraform state files
# 2. Blocks modification of credential and vault password files
# 3. Warns on Terraform changes (state, security groups, IAM, networking)
# 4. Warns on Kubernetes secret manifests and privileged containers
# 5. Warns on Dockerfile security issues
# 6. Warns on CI/CD pipeline token exposure
# 7. Warns on DNS and networking configuration changes
# 8. Suggests related files for review
# =============================================================================

set -euo pipefail

# Read hook input from stdin
HOOK_INPUT=$(cat)

# Extract tool name and file path from hook input
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

if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# Initialize arrays
CONTEXT_MESSAGES=()
WARNINGS=()

# Get file info
FILE_NAME=$(basename "$FILE_PATH")
FILE_DIR=$(dirname "$FILE_PATH")
FILE_EXT="${FILE_PATH##*.}"
FILE_NAME_LOWER=$(echo "$FILE_NAME" | tr '[:upper:]' '[:lower:]')
FILE_PATH_LOWER=$(echo "$FILE_PATH" | tr '[:upper:]' '[:lower:]')

# =============================================================================
# STATE FILE PROTECTION (BLOCK)
# =============================================================================

if echo "$FILE_NAME_LOWER" | grep -qE "\.tfstate$|\.tfstate\.backup$|\.tfstate\..+$"; then
    echo "{\"decision\":\"block\",\"reason\":\"Direct modification of Terraform state files is dangerous. Use 'terraform state' commands (terraform state mv, terraform state rm, terraform import) to manage state safely.\"}"
    exit 0
fi

# =============================================================================
# CREDENTIAL FILE PROTECTION (BLOCK)
# =============================================================================

if echo "$FILE_NAME_LOWER" | grep -qE "^(credentials|credentials\.json|service-account\.json|service-account-key\.json)$"; then
    echo "{\"decision\":\"block\",\"reason\":\"Direct modification of credential files is not allowed. Use a secret manager (AWS Secrets Manager, Vault, GCP Secret Manager) to manage credentials.\"}"
    exit 0
fi

if echo "$FILE_NAME_LOWER" | grep -qE "^(vault_password_file|\.vault_pass)$"; then
    echo "{\"decision\":\"block\",\"reason\":\"Ansible vault password files must never be modified through code generation. Manage vault passwords manually and securely.\"}"
    exit 0
fi

# =============================================================================
# TERRAFORM FILE DETECTION
# =============================================================================

IS_TERRAFORM=false

if echo "$FILE_EXT" | grep -qiE "^(tf|tfvars)$"; then
    IS_TERRAFORM=true

    # Detect what aspect of infrastructure is being modified
    if [ -f "$FILE_PATH" ]; then
        FILE_CONTENT=$(cat "$FILE_PATH" 2>/dev/null || echo "")

        # Security group changes
        if echo "$FILE_CONTENT" | grep -qE "aws_security_group|azurerm_network_security_group|google_compute_firewall" 2>/dev/null; then
            WARNINGS+=("NETWORKING: Modifying security group / firewall rules - verify no ports are opened to 0.0.0.0/0 unnecessarily")
        fi

        # IAM changes
        if echo "$FILE_CONTENT" | grep -qE "aws_iam|google_project_iam|azurerm_role_assignment|aws_iam_policy" 2>/dev/null; then
            WARNINGS+=("IAM: Modifying access control policies - verify principle of least privilege, no wildcard (*) actions or resources")
        fi

        # Networking changes
        if echo "$FILE_CONTENT" | grep -qE "aws_vpc|aws_subnet|aws_route|google_compute_network|azurerm_virtual_network" 2>/dev/null; then
            WARNINGS+=("NETWORKING: Modifying network infrastructure - changes may disrupt connectivity for running services")
        fi

        # DNS changes
        if echo "$FILE_CONTENT" | grep -qE "aws_route53|google_dns|azurerm_dns|cloudflare_record" 2>/dev/null; then
            WARNINGS+=("DNS: Modifying DNS records - incorrect changes can cause service outages. Verify TTL values and record targets.")
        fi

        # Database changes
        if echo "$FILE_CONTENT" | grep -qE "aws_db_instance|aws_rds|google_sql_database|azurerm_mysql|azurerm_postgresql" 2>/dev/null; then
            WARNINGS+=("DATABASE: Modifying database infrastructure - verify backup configuration, encryption, and multi-AZ settings. Some changes force replacement (data loss).")
            CONTEXT_MESSAGES+=("Database changes may trigger replacement (destroy + recreate). Run 'terraform plan' and check for 'forces replacement' warnings.")
        fi

        # S3 / Storage changes
        if echo "$FILE_CONTENT" | grep -qE "aws_s3_bucket|google_storage_bucket|azurerm_storage" 2>/dev/null; then
            CONTEXT_MESSAGES+=("Storage changes: verify encryption is enabled, public access is blocked, and versioning is configured.")
        fi

        # KMS / Encryption changes
        if echo "$FILE_CONTENT" | grep -qE "aws_kms|google_kms|azurerm_key_vault" 2>/dev/null; then
            WARNINGS+=("ENCRYPTION: Modifying encryption keys - key deletion or rotation may make data permanently inaccessible")
        fi
    fi

    # tfvars may contain secrets
    if echo "$FILE_EXT" | grep -qiE "^tfvars$"; then
        WARNINGS+=("SECRETS: Editing tfvars file - ensure no plaintext secrets. Use variable references to secret managers.")
    fi

    # Suggest running plan after changes
    CONTEXT_MESSAGES+=("After modifying Terraform files, run 'terraform plan' to preview changes before applying")
fi

# =============================================================================
# KUBERNETES MANIFEST DETECTION
# =============================================================================

IS_K8S=false

if echo "$FILE_PATH_LOWER" | grep -qE "/(k8s|kubernetes|manifests|charts|helm|deploy)/" 2>/dev/null; then
    if echo "$FILE_EXT" | grep -qiE "^(yaml|yml|json)$"; then
        IS_K8S=true
    fi
fi

if [ "$IS_K8S" = true ] && [ -f "$FILE_PATH" ]; then
    FILE_CONTENT=$(cat "$FILE_PATH" 2>/dev/null || echo "")

    # Secret manifests
    if echo "$FILE_CONTENT" | grep -q "kind: Secret" 2>/dev/null; then
        WARNINGS+=("K8S SECRETS: Kubernetes Secret manifest detected. Base64 is NOT encryption. Use External Secrets Operator, Sealed Secrets, or mount from a secret manager.")
    fi

    # Privileged containers
    if echo "$FILE_CONTENT" | grep -q "privileged: true" 2>/dev/null; then
        WARNINGS+=("K8S SECURITY: Privileged container detected - runs with full host access. Verify this is absolutely necessary.")
    fi

    # Host networking
    if echo "$FILE_CONTENT" | grep -q "hostNetwork: true" 2>/dev/null; then
        WARNINGS+=("K8S SECURITY: Host networking enabled - container shares the node network stack. Verify this is intentional.")
    fi

    # Missing resource limits
    if echo "$FILE_CONTENT" | grep -q "kind: Deployment" 2>/dev/null; then
        if ! echo "$FILE_CONTENT" | grep -q "resources:" 2>/dev/null; then
            CONTEXT_MESSAGES+=("K8s Deployment without resource limits - add requests and limits for CPU and memory")
        fi
    fi

    # Missing probes
    if echo "$FILE_CONTENT" | grep -q "kind: Deployment" 2>/dev/null; then
        if ! echo "$FILE_CONTENT" | grep -qE "readinessProbe:|livenessProbe:" 2>/dev/null; then
            CONTEXT_MESSAGES+=("K8s Deployment without health probes - add readinessProbe and livenessProbe")
        fi
    fi

    # Namespace changes
    if echo "$FILE_CONTENT" | grep -qE "kind: Namespace|kind: ResourceQuota|kind: LimitRange" 2>/dev/null; then
        WARNINGS+=("K8S NAMESPACE: Modifying namespace configuration - changes affect all resources in the namespace")
    fi

    # Network policies
    if echo "$FILE_CONTENT" | grep -q "kind: NetworkPolicy" 2>/dev/null; then
        WARNINGS+=("K8S NETWORKING: Modifying network policy - incorrect rules can block legitimate traffic between services")
    fi

    # RBAC changes
    if echo "$FILE_CONTENT" | grep -qE "kind: (Cluster)?Role|kind: (Cluster)?RoleBinding" 2>/dev/null; then
        WARNINGS+=("K8S RBAC: Modifying cluster access control - verify minimum necessary permissions")
    fi
fi

# =============================================================================
# DOCKERFILE DETECTION
# =============================================================================

if echo "$FILE_NAME_LOWER" | grep -qE "^dockerfile"; then
    if [ -f "$FILE_PATH" ]; then
        FILE_CONTENT=$(cat "$FILE_PATH" 2>/dev/null || echo "")

        # Secrets in build args
        if echo "$FILE_CONTENT" | grep -qiE "ARG.*(password|secret|token|key|credential)" 2>/dev/null; then
            WARNINGS+=("DOCKER SECRETS: Build ARG may contain secrets - ARGs are visible in image history. Use runtime environment variables or secret mounts instead.")
        fi

        # COPY of secret files
        if echo "$FILE_CONTENT" | grep -qE "^(COPY|ADD)\s+.*\.(env|pem|key|cert|p12|pfx)" 2>/dev/null; then
            WARNINGS+=("DOCKER SECRETS: Copying secret/key files into image - use Docker secrets, volume mounts, or multi-stage builds to avoid baking secrets into images")
        fi
    fi

    CONTEXT_MESSAGES+=("Dockerfile checklist: pin base image version, use multi-stage build, run as non-root user, add HEALTHCHECK, minimize layers")
fi

# =============================================================================
# CI/CD PIPELINE DETECTION
# =============================================================================

IS_CI=false

if echo "$FILE_PATH_LOWER" | grep -qE "/(\.github/workflows|\.circleci|\.buildkite)/" 2>/dev/null; then
    IS_CI=true
fi
if echo "$FILE_NAME_LOWER" | grep -qE "^(jenkinsfile|\.gitlab-ci\.yml|\.travis\.yml|azure-pipelines\.yml|bitbucket-pipelines\.yml|\.drone\.yml)$" 2>/dev/null; then
    IS_CI=true
fi

if [ "$IS_CI" = true ]; then
    WARNINGS+=("CI/CD: Modifying pipeline configuration - ensure secrets are not logged, use OIDC over long-lived tokens, pin action versions by SHA")

    if [ -f "$FILE_PATH" ]; then
        FILE_CONTENT=$(cat "$FILE_PATH" 2>/dev/null || echo "")

        # Hardcoded tokens
        if echo "$FILE_CONTENT" | grep -qE "(ghp_|gho_|github_pat_|glpat-|AKIA)[a-zA-Z0-9]" 2>/dev/null; then
            WARNINGS+=("CRITICAL: Token/credential detected in CI config - use repository secrets or OIDC, never hardcode tokens")
        fi

        # Unpinned actions
        if echo "$FILE_CONTENT" | grep -qE "uses:\s+\S+@(main|master|latest)" 2>/dev/null; then
            CONTEXT_MESSAGES+=("CI/CD: Actions pinned to branch names (main/master/latest) - pin to SHA for supply chain security")
        fi
    fi
fi

# =============================================================================
# ENVIRONMENT FILE DETECTION
# =============================================================================

if echo "$FILE_NAME_LOWER" | grep -qE "^\.env|\.env\.|env\.local|env\.production|env\.staging"; then
    WARNINGS+=("SECRETS: Modifying environment file - never commit secrets to git. Use a secret manager for production.")
fi

# =============================================================================
# ANSIBLE DETECTION
# =============================================================================

if echo "$FILE_PATH_LOWER" | grep -qE "/(playbooks|roles|inventory|group_vars|host_vars)/" 2>/dev/null; then
    CONTEXT_MESSAGES+=("Ansible: verify playbook is idempotent, use vault for secrets, test with --check before applying")

    if [ -f "$FILE_PATH" ]; then
        if grep -qE "ansible_become_password|ansible_ssh_pass" "$FILE_PATH" 2>/dev/null; then
            WARNINGS+=("ANSIBLE SECRETS: Plaintext credentials in Ansible config - use Ansible Vault to encrypt sensitive variables")
        fi
    fi
fi

# =============================================================================
# OUTPUT STRUCTURED RESPONSE
# =============================================================================

if [ ${#CONTEXT_MESSAGES[@]} -gt 0 ] || [ ${#WARNINGS[@]} -gt 0 ]; then
    OUTPUT="{"
    FIRST_SECTION=true

    if [ ${#CONTEXT_MESSAGES[@]} -gt 0 ]; then
        OUTPUT="$OUTPUT\"additionalContext\":["
        FIRST=true
        for msg in "${CONTEXT_MESSAGES[@]}"; do
            if [ "$FIRST" = true ]; then FIRST=false; else OUTPUT="$OUTPUT,"; fi
            ESCAPED_MSG=$(echo "$msg" | sed 's/"/\\"/g')
            OUTPUT="$OUTPUT{\"type\":\"text\",\"text\":\"$ESCAPED_MSG\"}"
        done
        OUTPUT="$OUTPUT]"
        FIRST_SECTION=false
    fi

    if [ ${#WARNINGS[@]} -gt 0 ]; then
        if [ "$FIRST_SECTION" = false ]; then OUTPUT="$OUTPUT,"; fi
        OUTPUT="$OUTPUT\"systemMessage\":\"LibreDevOps Pre-Edit Infrastructure Check:\\n"
        for warn in "${WARNINGS[@]}"; do
            ESCAPED_WARN=$(echo "$warn" | sed 's/"/\\"/g')
            OUTPUT="$OUTPUT- $ESCAPED_WARN\\n"
        done
        OUTPUT="$OUTPUT\""
    fi

    OUTPUT="$OUTPUT}"
    echo "$OUTPUT"
fi

exit 0
