#!/usr/bin/env bash
# =============================================================================
# LibreDevOps PostToolUse hook (Edit, Write, MultiEdit)
# =============================================================================
# After Claude writes a file, check it the way an infrastructure reviewer
# would and hand any findings back to Claude as context:
#   1. Terraform: formatting, hardcoded secrets, missing remote state backend,
#      0.0.0.0/0 ingress, missing encryption, wildcard IAM, public databases,
#      IMDSv2, tags, loose provider constraints, replacement-prone changes
#   2. Kubernetes: Secrets, privileged/host access, resources, probes,
#      root user, :latest images, single replicas, cluster-admin
#   3. Dockerfiles: root user, unpinned base, copied secrets, ADD with URL,
#      HEALTHCHECK, npm ci, .dockerignore, secrets in build args
#   4. CI/CD: hardcoded tokens, unpinned actions, secret echo, permissions,
#      job timeouts
#   5. Docker Compose: resource limits, hardcoded passwords, exposed DB ports,
#      :latest images
#   6. Ansible: plaintext credentials
#   7. Any file: AWS keys, GitHub tokens, private keys, DB URLs with
#      passwords, Stripe live keys
#   8. .gitignore coverage for .env and Terraform state (infrastructure files)
#
# Quiet by design: prints nothing when there are no findings and writes no
# files. Nothing here blocks the edit.
#
# Input:  hook JSON on stdin (tool_name, tool_input.file_path)
# Output: {"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":...}}
# Needs:  jq (exits silently without it)
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

command -v jq >/dev/null 2>&1 || exit 0

INPUT="$(cat || true)"
TOOL="$(jq -r '.tool_name // empty' <<<"$INPUT" 2>/dev/null || true)"
FILE="$(jq -r '.tool_input.file_path // empty' <<<"$INPUT" 2>/dev/null || true)"

case "$TOOL" in Edit|Write|MultiEdit) ;; *) exit 0 ;; esac
[[ -n "$FILE" && -f "$FILE" ]] || exit 0

NAME="$(basename "$FILE")"
LNAME="$(printf '%s' "$NAME" | tr '[:upper:]' '[:lower:]')"
LPATH="$(printf '%s' "$FILE" | tr '[:upper:]' '[:lower:]')"
DIR="$(dirname "$FILE")"
EXT="${LNAME##*.}"
[[ "$LNAME" == *.* ]] || EXT=""

case "$EXT" in
  png|jpg|jpeg|gif|webp|ico|svg|pdf|zip|gz|tgz|tar|woff|woff2|ttf|eot|mp3|mp4|mov|so|dylib|exe|bin) exit 0 ;;
esac

CONTENT="$(head -c 262144 "$FILE" 2>/dev/null || true)"
has()  { grep -qE  -- "$1" <<<"$CONTENT"; }
hasi() { grep -qiE -- "$1" <<<"$CONTENT"; }

FINDINGS=()
add() { FINDINGS+=("$1"); }
IS_INFRA=false

# --- 1. Terraform ---------------------------------------------------------------
IS_TF=false
case "$EXT" in tf|tfvars) IS_TF=true ;; esac
if [[ "$LNAME" == *.tfvars.json ]]; then IS_TF=true; fi

if [[ "$IS_TF" == true ]]; then
  IS_INFRA=true
  if command -v terraform >/dev/null 2>&1 && ! terraform fmt -check "$FILE" >/dev/null 2>&1; then
    add "Terraform format: the file is not formatted. Run: terraform fmt $FILE"
  fi
  if has '(password|secret|token|api_key)[[:space:]]*=[[:space:]]*"[^${}][^"]{4,}"'; then
    add "Terraform secrets: a value looks like a hardcoded secret. Reference a secret manager instead (aws_secretsmanager_secret, google_secret_manager_secret, azurerm_key_vault_secret)."
  fi
  if [[ "$EXT" == "tfvars" ]]; then
    add "Terraform tfvars: keep plaintext secrets out of tfvars; pass them from a secret manager or the environment."
  fi
  if [[ "$EXT" == "tf" && "$LPATH" != */modules/* ]] \
    && ! grep -qE 'backend[[:space:]]+"|^[[:space:]]*cloud[[:space:]]*\{' "$DIR"/*.tf 2>/dev/null \
    && grep -qE '^[[:space:]]*resource[[:space:]]+"' "$DIR"/*.tf 2>/dev/null; then
    add "Terraform state: no remote backend in $DIR. Add a backend block (S3, GCS, Azure Blob) with encryption and locking."
  fi
  if has 'cidr_blocks[[:space:]]*=[[:space:]]*\["0\.0\.0\.0/0"\]' && has 'ingress|inbound'; then
    add "Terraform security: a security group allows ingress from 0.0.0.0/0. Restrict the CIDR unless this is a public load balancer on 80/443."
  fi
  if has 'source_address_prefix[[:space:]]*=[[:space:]]*"\*"'; then
    add "Terraform security: an Azure NSG rule allows any source (*). Restrict the address prefixes."
  fi
  if has 'source_ranges[[:space:]]*=[[:space:]]*\["0\.0\.0\.0/0"\]'; then
    add "Terraform security: a GCP firewall rule allows 0.0.0.0/0. Restrict the source ranges."
  fi
  if has '"aws_s3_bucket"' && ! has 'server_side_encryption_configuration|aws_s3_bucket_server_side_encryption'; then
    add "Terraform encryption: S3 bucket without explicit encryption. Add aws_s3_bucket_server_side_encryption_configuration."
  fi
  if has '"aws_db_instance"|"aws_rds_cluster"' && ! has 'storage_encrypted'; then
    add "Terraform encryption: RDS without storage_encrypted = true."
  fi
  if has '"aws_ebs_volume"' && ! has 'encrypted'; then
    add "Terraform encryption: EBS volume without encrypted = true."
  fi
  if has '"actions"[[:space:]]*:[[:space:]]*\["\*"\]|actions[[:space:]]*=[[:space:]]*\["\*"\]|"Action"[[:space:]]*:[[:space:]]*"\*"'; then
    add "Terraform IAM: wildcard (*) actions in a policy. Grant only the specific actions needed."
  fi
  if has '"resources"[[:space:]]*:[[:space:]]*\["\*"\]|resources[[:space:]]*=[[:space:]]*\["\*"\]|"Resource"[[:space:]]*:[[:space:]]*"\*"'; then
    add "Terraform IAM: wildcard (*) resources in a policy. Scope to specific ARNs."
  fi
  if has 'publicly_accessible[[:space:]]*=[[:space:]]*true'; then
    add "Terraform security: database has publicly_accessible = true. Keep databases in private subnets behind a bastion or VPN."
  fi
  if has '"aws_instance"|"aws_launch_template"' && ! has 'http_tokens'; then
    add "Terraform security: EC2 without IMDSv2 enforcement. Add metadata_options { http_tokens = \"required\" } to block SSRF credential theft."
  fi
  if has 'resource[[:space:]]+"aws_' && ! has 'tags'; then
    add "Terraform tags: AWS resources without tags. Add Project, Environment, and ManagedBy tags for cost and ownership tracking."
  fi
  if has 'required_providers' && has 'version[[:space:]]*=[[:space:]]*">='; then
    add "Terraform providers: a provider uses a >= constraint. Pin it, or use ~> to allow only compatible updates."
  fi
  if has '"aws_db_instance"|"aws_rds_cluster"|"google_sql_database|"azurerm_(mysql|postgresql)'; then
    add "Terraform databases: some database changes force replacement (destroy and recreate). Check terraform plan for 'forces replacement' before applying."
  fi
  if has '"aws_kms|"google_kms|"azurerm_key_vault'; then
    add "Terraform encryption keys: deleting or replacing a key can make data permanently unreadable. Review key changes in the plan."
  fi
fi

# --- 2. Kubernetes ----------------------------------------------------------------
IS_K8S=false
case "$EXT" in
  yaml|yml|json)
    if [[ "$LPATH" =~ /(k8s|kubernetes|manifests|charts|helm|deploy)/ ]] \
      || has '^kind:[[:space:]]+(Deployment|Service|Pod|StatefulSet|DaemonSet|Job|CronJob|Ingress|ConfigMap|Secret|Namespace)'; then
      IS_K8S=true
    fi ;;
esac

if [[ "$IS_K8S" == true ]]; then
  IS_INFRA=true
  has 'kind:[[:space:]]*Secret([[:space:]]|$)' && add "Kubernetes secrets: this writes a Secret manifest. Base64 is not encryption; use External Secrets Operator, Sealed Secrets, or a secret manager."
  has 'privileged:[[:space:]]*true' && add "Kubernetes security: privileged container (full host access). Remove unless required, for example by a CNI or storage driver."
  has 'hostNetwork:[[:space:]]*true' && add "Kubernetes security: hostNetwork is on, which shares the node network and bypasses NetworkPolicies."
  has 'hostPID:[[:space:]]*true' && add "Kubernetes security: hostPID is on; the container can see every process on the node."
  if has 'kind:[[:space:]]*(Deployment|StatefulSet|DaemonSet)' && ! has 'resources:'; then
    add "Kubernetes resources: workload without resource requests and limits."
  fi
  if has 'kind:[[:space:]]*(Deployment|StatefulSet)' && ! has 'readinessProbe:|livenessProbe:'; then
    add "Kubernetes probes: workload without readinessProbe or livenessProbe."
  fi
  has 'runAsNonRoot:[[:space:]]*false' && add "Kubernetes security: runAsNonRoot is false. Run as a non-root runAsUser."
  has 'image:.*:latest' && add "Kubernetes images: an image uses :latest. Pin a version or digest for reproducible rollouts and rollbacks."
  if has 'kind:[[:space:]]*Deployment' && has 'replicas:[[:space:]]*1[[:space:]]*$'; then
    add "Kubernetes availability: Deployment with 1 replica. Use several replicas and a PodDisruptionBudget for high availability."
  fi
  has 'cluster-admin' && add "Kubernetes RBAC: binds cluster-admin. Use a scoped Role with the minimum permissions."
fi

# --- 3. Dockerfile ----------------------------------------------------------------
if [[ "$LNAME" == dockerfile* || "$LNAME" == *.dockerfile ]]; then
  IS_INFRA=true
  has '^USER[[:space:]]' || add "Docker security: no USER instruction, so the container runs as root. Add a non-root USER after installing packages."
  has '^FROM[[:space:]]+[^[:space:]]+:latest([[:space:]]|$)' && add "Docker images: a base image uses :latest. Pin a specific version."
  has '^FROM[[:space:]]+[^[:space:]:@]+([[:space:]]+(AS|as)[[:space:]]+[^[:space:]]+)?[[:space:]]*$' && ! has '^FROM[[:space:]]+scratch' \
    && add "Docker images: a base image has no tag (implies :latest). Pin a specific version."
  has '^(COPY|ADD)[[:space:]]+.*\.(env|pem|key|cert|p12|pfx|jks)' && add "Docker secrets: a secret or key file is copied into an image layer. Use BuildKit secret mounts (--mount=type=secret) or runtime secrets."
  has '^ADD[[:space:]]+https?://' && add "Docker: ADD with a URL. Download with RUN curl or wget and verify a checksum instead."
  has '^HEALTHCHECK' || add "Docker health: no HEALTHCHECK instruction."
  if has 'npm install' && ! has 'npm ci'; then
    add "Docker Node: uses npm install. Use npm ci for deterministic installs from the lockfile."
  fi
  [[ -f "$DIR/.dockerignore" ]] || add "Docker build: no .dockerignore next to the Dockerfile. Exclude .git, node_modules, and .env files from the build context."
  hasi '^ARG.*(password|secret|token|key|credential)' && add "Docker secrets: a build ARG looks like a secret; ARG values show in docker history. Use BuildKit secret mounts."
fi

# --- 4. CI/CD ------------------------------------------------------------------------
IS_CI=false
if [[ "$LPATH" =~ /(\.github/workflows|\.circleci|\.buildkite)/ ]] \
  || [[ "$LNAME" =~ ^(jenkinsfile|\.gitlab-ci\.yml|\.travis\.yml|azure-pipelines\.yml|bitbucket-pipelines\.yml|\.drone\.yml)$ ]]; then
  IS_CI=true
fi

if [[ "$IS_CI" == true ]]; then
  IS_INFRA=true
  has '(ghp_|gho_|github_pat_)[a-zA-Z0-9_]{20,}' && add "CI/CD critical: a GitHub token is in the pipeline file. Remove it, rotate it, and use repository secrets."
  has 'glpat-[a-zA-Z0-9_-]{20,}' && add "CI/CD critical: a GitLab personal access token is in the pipeline file. Remove it, rotate it, and use CI/CD variables."
  has 'AKIA[A-Z0-9]{16}' && add "CI/CD critical: an AWS access key is in the pipeline file. Remove it and use OIDC federation or secrets."
  has 'uses:[[:space:]]+[^[:space:]]+@(main|master|latest)([[:space:]]|$)' && add "CI/CD supply chain: actions pinned to a branch (main, master, latest). Pin to a full commit SHA."
  has 'uses:[[:space:]]+[^[:space:]]+@v[0-9]+[[:space:]]*$' && add "CI/CD supply chain: actions pinned to a major tag such as @v4. Pin to a full commit SHA with a version comment."
  hasi 'echo.*\$\{\{[[:space:]]*secrets\.' && add "CI/CD secrets: a secret is echoed. Never print secret values; masking does not cover derived values."
  has 'permissions:[[:space:]]*write-all' && add "CI/CD permissions: write-all. Grant only what each job needs (contents: read, packages: write, ...)."
  if [[ "$LPATH" == */.github/workflows/* ]]; then
    has 'permissions:' || add "CI/CD permissions: no permissions block. Add top-level permissions to restrict GITHUB_TOKEN."
    has 'timeout-minutes:' || add "CI/CD: no timeout-minutes. Set one so a hung job cannot hold a runner indefinitely."
  fi
fi

# --- 5. Docker Compose ------------------------------------------------------------
if [[ "$LNAME" =~ ^(docker-compose|compose)([.-].*)?\.ya?ml$ ]]; then
  IS_INFRA=true
  if has 'services:' && ! has 'mem_limit|deploy:'; then
    add "Compose resources: no memory limits. Add mem_limit or deploy.resources.limits."
  fi
  hasi '(MYSQL_ROOT_PASSWORD|POSTGRES_PASSWORD|MONGO_INITDB_ROOT_PASSWORD|REDIS_PASSWORD)[:=][[:space:]]*[a-zA-Z0-9]' \
    && add "Compose secrets: a database password is hardcoded. Load it from an .env file or Docker secrets."
  has '^[[:space:]]*-[[:space:]]*"?([0-9.]+:)?(3306|5432|27017|6379|9200):[0-9]+' \
    && add "Compose networking: a database port is published on the host. Reach databases over the compose network instead."
  has 'image:.*:latest' && add "Compose images: a service uses :latest. Pin a version."
fi

# --- 6. Ansible -------------------------------------------------------------------
if [[ "$LPATH" =~ /(playbooks|roles|inventory|group_vars|host_vars)/ ]]; then
  IS_INFRA=true
  has 'ansible_become_password|ansible_ssh_pass|ansible_password' \
    && add "Ansible secrets: plaintext connection credentials. Encrypt them with ansible-vault encrypt_string."
  if hasi '(password|secret|token|api_key):[[:space:]]*["'"'"'a-zA-Z0-9][^{]' && ! has '!vault'; then
    add "Ansible secrets: a variable looks like a plaintext secret. Encrypt it with Ansible Vault."
  fi
fi

# --- 7. Secrets in any file ------------------------------------------------------------
if [[ "$LNAME" =~ ^\.env ]]; then
  IS_INFRA=true
  has '(AKIA|ghp_|gho_|sk-|sk_live_|rk_live_|glpat-)' \
    && add "Env file critical: a real credential is in this file. Make sure .gitignore excludes it and it is never committed."
else
  if [[ "$IS_CI" == false ]]; then
    has 'AKIA[A-Z0-9]{16}' && add "Secret detected: an AWS access key ID (AKIA...). Use IAM roles, instance profiles, or OIDC federation."
    has '(ghp_|gho_|github_pat_)[a-zA-Z0-9_]{20,}' && add "Secret detected: a GitHub token. Use GITHUB_TOKEN or deploy keys."
  fi
  has 'BEGIN[A-Z ]*PRIVATE KEY' && add "Secret detected: a private key. Keep keys in a secret manager or certificate store."
  hasi '(mysql|postgres|postgresql|mongodb|redis)://[^:/[:space:]]+:[^@[:space:]]+@' && add "Secret detected: a database URL with an embedded password. Use environment variables or a secret manager reference."
  has '(sk_live_|rk_live_)[a-zA-Z0-9]+' && add "Secret detected: a Stripe live secret key. Remove it and load it from the environment."
fi

# --- 8. .gitignore coverage (infrastructure files only) --------------------------------
if [[ "$IS_INFRA" == true ]] && command -v git >/dev/null 2>&1; then
  ROOT="$(git -C "$DIR" rev-parse --show-toplevel 2>/dev/null || true)"
  if [[ -n "$ROOT" && -f "$ROOT/.gitignore" ]]; then
    grep -q '\.env' "$ROOT/.gitignore" || add ".gitignore: no .env exclusion. Add .env* to keep secrets out of commits."
    if [[ "$IS_TF" == true ]] && ! grep -q 'tfstate' "$ROOT/.gitignore"; then
      add ".gitignore: no Terraform state exclusion. Add *.tfstate and *.tfstate.*."
    fi
  fi
fi

(( ${#FINDINGS[@]} > 0 )) || exit 0

CONTEXT="LibreDevOps post-edit checks for $FILE:"
for f in "${FINDINGS[@]}"; do CONTEXT+=$'\n'"- $f"; done

jq -n --arg ctx "$CONTEXT" '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: $ctx
  }
}'
exit 0
