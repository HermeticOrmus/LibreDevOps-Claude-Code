#!/bin/bash
# =============================================================================
# LibreDevOps Session Start Hook
# =============================================================================
# Runs when a Claude Code session starts in a project.
# Detects infrastructure tools, CI/CD configs, cloud providers, container
# setup, and monitoring stack. Recommends relevant LibreDevOps plugins.
#
# What this hook does:
# 1. Detects IaC tools (Terraform, Pulumi, CloudFormation, Ansible)
# 2. Identifies CI/CD configurations (GitHub Actions, GitLab CI, Jenkins)
# 3. Detects cloud providers from configs and credentials
# 4. Finds container setup (Docker, Kubernetes, Helm)
# 5. Identifies monitoring stack (Prometheus, Grafana, Datadog, CloudWatch)
# 6. Checks for state management (remote backends, lockfiles)
# 7. Warns about missing infrastructure basics
# 8. Recommends relevant LibreDevOps plugins
# =============================================================================

set -euo pipefail

# Read hook input from stdin
HOOK_INPUT=$(cat)

# Get current working directory
CURRENT_DIR=$(pwd)
PROJECT_NAME=$(basename "$CURRENT_DIR")

# Ensure log directory exists
HOOKS_LOG_DIR="${LIBREDEVOPS_HOOKS_DIR:-$(dirname "$0")}/logs"
mkdir -p "$HOOKS_LOG_DIR"

# Log session start
echo "$(date '+%Y-%m-%d %H:%M:%S') - LibreDevOps Session started in $CURRENT_DIR" >> "$HOOKS_LOG_DIR/sessions.log"

# Initialize output arrays
CONTEXT_MESSAGES=()
INFRA_CONTEXT=()
WARNINGS=()

# =============================================================================
# IAC TOOL DETECTION
# =============================================================================

IAC_TOOLS=()
HAS_STATE_BACKEND=false

# Terraform
if find "$CURRENT_DIR" -maxdepth 3 -name "*.tf" -print -quit 2>/dev/null | grep -q .; then
    IAC_TOOLS+=("Terraform")

    # Check for terraform version
    if command -v terraform &>/dev/null; then
        TF_VER=$(terraform version -json 2>/dev/null | grep -o '"terraform_version":"[^"]*"' | cut -d'"' -f4 || true)
        [ -n "$TF_VER" ] && INFRA_CONTEXT+=("Terraform version: $TF_VER")
    fi

    # Check for remote state backend
    if grep -rl 'backend\s*"s3"\|backend\s*"gcs"\|backend\s*"azurerm"\|backend\s*"remote"\|backend\s*"consul"\|backend\s*"http"' "$CURRENT_DIR" --include="*.tf" -m 1 2>/dev/null | grep -q .; then
        HAS_STATE_BACKEND=true
        BACKEND_TYPE=$(grep -rh 'backend\s*"' "$CURRENT_DIR" --include="*.tf" 2>/dev/null | head -1 | sed 's/.*backend\s*"\([^"]*\)".*/\1/')
        INFRA_CONTEXT+=("Terraform state backend: $BACKEND_TYPE")
    else
        WARNINGS+=("WARNING: Terraform files found but no remote state backend detected - state is stored locally (risk of loss and no locking)")
    fi

    # Check for .terraform.lock.hcl
    if [ -f "$CURRENT_DIR/.terraform.lock.hcl" ]; then
        INFRA_CONTEXT+=("Terraform provider lockfile present")
    fi

    # Check for tfvars files
    TFVARS_COUNT=$(find "$CURRENT_DIR" -maxdepth 3 -name "*.tfvars" -o -name "*.tfvars.json" 2>/dev/null | wc -l)
    if [ "$TFVARS_COUNT" -gt 0 ]; then
        INFRA_CONTEXT+=("$TFVARS_COUNT tfvars file(s) found")
    fi

    # Check for state files committed (should NOT be in repo)
    if find "$CURRENT_DIR" -maxdepth 3 -name "*.tfstate" -print -quit 2>/dev/null | grep -q .; then
        WARNINGS+=("CRITICAL: Terraform state file (.tfstate) found in repository - state files contain sensitive data and should not be committed")
    fi

    # Detect module structure
    if [ -d "$CURRENT_DIR/modules" ] || [ -d "$CURRENT_DIR/infrastructure/modules" ]; then
        INFRA_CONTEXT+=("Terraform module structure detected")
    fi

    # Detect environment directories
    if [ -d "$CURRENT_DIR/environments" ] || [ -d "$CURRENT_DIR/infrastructure/environments" ]; then
        INFRA_CONTEXT+=("Multi-environment directory structure detected")
    fi
fi

# Pulumi
if [ -f "$CURRENT_DIR/Pulumi.yaml" ]; then
    IAC_TOOLS+=("Pulumi")
fi

# CloudFormation
if grep -rl "AWSTemplateFormatVersion" "$CURRENT_DIR" --include="*.yaml" --include="*.yml" --include="*.json" -m 1 2>/dev/null | grep -q .; then
    IAC_TOOLS+=("CloudFormation")
fi

# AWS CDK
if [ -f "$CURRENT_DIR/cdk.json" ]; then
    IAC_TOOLS+=("AWS CDK")
fi

# Ansible
if [ -f "$CURRENT_DIR/ansible.cfg" ] || [ -f "$CURRENT_DIR/playbook.yml" ] || [ -d "$CURRENT_DIR/playbooks" ] || [ -d "$CURRENT_DIR/roles" ]; then
    IAC_TOOLS+=("Ansible")

    if find "$CURRENT_DIR" -maxdepth 3 -name "*vault*" -print -quit 2>/dev/null | grep -q .; then
        INFRA_CONTEXT+=("Ansible Vault files detected")
    fi
    if [ -f "$CURRENT_DIR/inventory" ] || [ -f "$CURRENT_DIR/inventory.yml" ] || [ -d "$CURRENT_DIR/inventory" ]; then
        INFRA_CONTEXT+=("Ansible inventory detected")
    fi
fi

# Vagrant
if [ -f "$CURRENT_DIR/Vagrantfile" ]; then
    IAC_TOOLS+=("Vagrant")
fi

# Packer
if find "$CURRENT_DIR" -maxdepth 2 -name "*.pkr.hcl" -o -name "*.pkr.json" -print -quit 2>/dev/null | grep -q .; then
    IAC_TOOLS+=("Packer")
fi

if [ ${#IAC_TOOLS[@]} -gt 0 ]; then
    CONTEXT_MESSAGES+=("IaC tools: ${IAC_TOOLS[*]}")
fi

# =============================================================================
# CI/CD DETECTION
# =============================================================================

CI_SYSTEMS=()

if [ -d "$CURRENT_DIR/.github/workflows" ]; then
    CI_SYSTEMS+=("GitHub Actions")
    WORKFLOW_COUNT=$(find "$CURRENT_DIR/.github/workflows" -name "*.yml" -o -name "*.yaml" 2>/dev/null | wc -l)
    INFRA_CONTEXT+=("GitHub Actions: $WORKFLOW_COUNT workflow(s)")
fi
if [ -f "$CURRENT_DIR/.gitlab-ci.yml" ]; then CI_SYSTEMS+=("GitLab CI"); fi
if [ -f "$CURRENT_DIR/Jenkinsfile" ]; then CI_SYSTEMS+=("Jenkins"); fi
if [ -f "$CURRENT_DIR/.circleci/config.yml" ]; then CI_SYSTEMS+=("CircleCI"); fi
if [ -f "$CURRENT_DIR/.travis.yml" ]; then CI_SYSTEMS+=("Travis CI"); fi
if [ -d "$CURRENT_DIR/.buildkite" ]; then CI_SYSTEMS+=("Buildkite"); fi
if [ -f "$CURRENT_DIR/azure-pipelines.yml" ]; then CI_SYSTEMS+=("Azure Pipelines"); fi
if [ -f "$CURRENT_DIR/bitbucket-pipelines.yml" ]; then CI_SYSTEMS+=("Bitbucket Pipelines"); fi
if [ -f "$CURRENT_DIR/.drone.yml" ]; then CI_SYSTEMS+=("Drone CI"); fi

if [ ${#CI_SYSTEMS[@]} -gt 0 ]; then
    CONTEXT_MESSAGES+=("CI/CD: ${CI_SYSTEMS[*]}")
fi

# =============================================================================
# CLOUD PROVIDER DETECTION
# =============================================================================

CLOUD_PROVIDERS=()

# AWS
if grep -rl 'provider\s*"aws"' "$CURRENT_DIR" --include="*.tf" -m 1 2>/dev/null | grep -q .; then
    CLOUD_PROVIDERS+=("AWS")
elif grep -rl "aws_" "$CURRENT_DIR" --include="*.tf" -m 1 2>/dev/null | grep -q .; then
    CLOUD_PROVIDERS+=("AWS")
fi

# GCP
if grep -rl 'provider\s*"google"' "$CURRENT_DIR" --include="*.tf" -m 1 2>/dev/null | grep -q .; then
    CLOUD_PROVIDERS+=("GCP")
elif grep -rl "google_" "$CURRENT_DIR" --include="*.tf" -m 1 2>/dev/null | grep -q .; then
    CLOUD_PROVIDERS+=("GCP")
fi

# Azure
if grep -rl 'provider\s*"azurerm"' "$CURRENT_DIR" --include="*.tf" -m 1 2>/dev/null | grep -q .; then
    CLOUD_PROVIDERS+=("Azure")
elif grep -rl "azurerm_" "$CURRENT_DIR" --include="*.tf" -m 1 2>/dev/null | grep -q .; then
    CLOUD_PROVIDERS+=("Azure")
fi

# DigitalOcean
if grep -rl 'provider\s*"digitalocean"' "$CURRENT_DIR" --include="*.tf" -m 1 2>/dev/null | grep -q .; then
    CLOUD_PROVIDERS+=("DigitalOcean")
fi

# Deduplicate
if [ ${#CLOUD_PROVIDERS[@]} -gt 0 ]; then
    UNIQUE_PROVIDERS=$(printf '%s\n' "${CLOUD_PROVIDERS[@]}" | sort -u | tr '\n' ', ' | sed 's/,$//')
    CONTEXT_MESSAGES+=("Cloud providers: $UNIQUE_PROVIDERS")
fi

# =============================================================================
# CONTAINER AND ORCHESTRATION DETECTION
# =============================================================================

HAS_DOCKER=false
HAS_K8S=false
HAS_HELM=false

# Docker
if [ -f "$CURRENT_DIR/Dockerfile" ] || [ -f "$CURRENT_DIR/docker-compose.yml" ] || [ -f "$CURRENT_DIR/docker-compose.yaml" ] || [ -f "$CURRENT_DIR/compose.yml" ] || [ -f "$CURRENT_DIR/compose.yaml" ]; then
    HAS_DOCKER=true
    INFRA_CONTEXT+=("Docker/container setup detected")

    # Check Dockerfile for common issues
    if [ -f "$CURRENT_DIR/Dockerfile" ]; then
        DOCKERFILE=$(cat "$CURRENT_DIR/Dockerfile" 2>/dev/null || echo "")
        if ! echo "$DOCKERFILE" | grep -q "^USER " 2>/dev/null; then
            WARNINGS+=("Dockerfile has no USER instruction - container runs as root by default")
        fi
        if echo "$DOCKERFILE" | grep -qE "^FROM\s+\S+:latest\b|^FROM\s+\S+\s*$" 2>/dev/null; then
            WARNINGS+=("Dockerfile uses :latest or unpinned image tag - pin to a specific version for reproducibility")
        fi
        if ! echo "$DOCKERFILE" | grep -q "^HEALTHCHECK " 2>/dev/null; then
            WARNINGS+=("Dockerfile has no HEALTHCHECK instruction - orchestrators cannot detect unhealthy containers")
        fi
    fi

    # Check Docker Compose for resource limits
    for f in docker-compose.yml docker-compose.yaml compose.yml compose.yaml; do
        if [ -f "$CURRENT_DIR/$f" ]; then
            COMPOSE_CONTENT=$(cat "$CURRENT_DIR/$f" 2>/dev/null || echo "")
            if ! echo "$COMPOSE_CONTENT" | grep -qE "deploy:|resources:|mem_limit|cpus:" 2>/dev/null; then
                WARNINGS+=("Docker Compose has no resource limits - containers can consume unlimited host resources")
            fi
            break
        fi
    done
fi

# Kubernetes
if [ -d "$CURRENT_DIR/k8s" ] || [ -d "$CURRENT_DIR/kubernetes" ] || [ -d "$CURRENT_DIR/manifests" ] || [ -d "$CURRENT_DIR/deploy" ]; then
    HAS_K8S=true
    INFRA_CONTEXT+=("Kubernetes manifests detected")
fi

# Helm
if [ -d "$CURRENT_DIR/charts" ] || [ -f "$CURRENT_DIR/Chart.yaml" ] || [ -d "$CURRENT_DIR/helm" ]; then
    HAS_HELM=true
    INFRA_CONTEXT+=("Helm charts detected")
fi

# Kustomize
if find "$CURRENT_DIR" -maxdepth 3 -name "kustomization.yaml" -o -name "kustomization.yml" -print -quit 2>/dev/null | grep -q .; then
    INFRA_CONTEXT+=("Kustomize overlays detected")
fi

# =============================================================================
# MONITORING STACK DETECTION
# =============================================================================

MONITORING_TOOLS=()

if find "$CURRENT_DIR" -maxdepth 3 -name "prometheus.yml" -o -name "prometheus.yaml" -print -quit 2>/dev/null | grep -q .; then
    MONITORING_TOOLS+=("Prometheus")
fi
if find "$CURRENT_DIR" -maxdepth 3 -name "grafana*" -print -quit 2>/dev/null | grep -q .; then
    MONITORING_TOOLS+=("Grafana")
fi
if find "$CURRENT_DIR" -maxdepth 3 -name "datadog*" -print -quit 2>/dev/null | grep -q .; then
    MONITORING_TOOLS+=("Datadog")
fi
if grep -rl "aws_cloudwatch" "$CURRENT_DIR" --include="*.tf" -m 1 2>/dev/null | grep -q .; then
    MONITORING_TOOLS+=("CloudWatch")
fi
if grep -rl "opentelemetry\|otel" "$CURRENT_DIR" --include="*.yaml" --include="*.yml" --include="*.json" -m 1 2>/dev/null | grep -q .; then
    MONITORING_TOOLS+=("OpenTelemetry")
fi

if [ ${#MONITORING_TOOLS[@]} -gt 0 ]; then
    INFRA_CONTEXT+=("Monitoring: ${MONITORING_TOOLS[*]}")
fi

# =============================================================================
# SECURITY TOOLING DETECTION
# =============================================================================

SECURITY_TOOLS=()

if [ -f "$CURRENT_DIR/.trivyignore" ] || [ -f "$CURRENT_DIR/trivy.yaml" ]; then SECURITY_TOOLS+=("Trivy"); fi
if [ -f "$CURRENT_DIR/.tfsec.yml" ]; then SECURITY_TOOLS+=("tfsec"); fi
if [ -f "$CURRENT_DIR/.checkov.yml" ] || [ -f "$CURRENT_DIR/.checkov.yaml" ]; then SECURITY_TOOLS+=("Checkov"); fi
if [ -f "$CURRENT_DIR/.gitleaks.toml" ]; then SECURITY_TOOLS+=("Gitleaks"); fi
if [ -f "$CURRENT_DIR/.snyk" ]; then SECURITY_TOOLS+=("Snyk"); fi
if [ -f "$CURRENT_DIR/.github/dependabot.yml" ]; then SECURITY_TOOLS+=("Dependabot"); fi
if [ -f "$CURRENT_DIR/renovate.json" ] || [ -f "$CURRENT_DIR/.renovaterc.json" ]; then SECURITY_TOOLS+=("Renovate"); fi

if [ ${#SECURITY_TOOLS[@]} -gt 0 ]; then
    INFRA_CONTEXT+=("Security tools: ${SECURITY_TOOLS[*]}")
fi

# =============================================================================
# INFRASTRUCTURE WARNINGS
# =============================================================================

# Check .gitignore
if [ -d "$CURRENT_DIR/.git" ] && [ -f "$CURRENT_DIR/.gitignore" ]; then
    GITIGNORE=$(cat "$CURRENT_DIR/.gitignore" 2>/dev/null || echo "")
    if [ ${#IAC_TOOLS[@]} -gt 0 ]; then
        if ! echo "$GITIGNORE" | grep -qE "\.terraform|\.tfstate|tfstate" 2>/dev/null; then
            WARNINGS+=("WARNING: .gitignore does not exclude Terraform state and .terraform directory")
        fi
    fi
    if ! echo "$GITIGNORE" | grep -qE "^\.env$|^\*\.env|^\.env\*" 2>/dev/null; then
        WARNINGS+=("WARNING: .gitignore does not appear to exclude .env files")
    fi
elif [ -d "$CURRENT_DIR/.git" ] && [ ! -f "$CURRENT_DIR/.gitignore" ]; then
    WARNINGS+=("CRITICAL: No .gitignore found in git repository")
fi

# Check for .env tracked by git
for env_file in ".env" ".env.local" ".env.production"; do
    if [ -f "$CURRENT_DIR/$env_file" ]; then
        if command -v git &>/dev/null && [ -d "$CURRENT_DIR/.git" ]; then
            if git -C "$CURRENT_DIR" ls-files --error-unmatch "$env_file" &>/dev/null 2>&1; then
                WARNINGS+=("CRITICAL: $env_file is tracked by git - secrets may be exposed in history")
            fi
        fi
    fi
done

# Check for private keys
if find "$CURRENT_DIR" -maxdepth 3 \( -name "*.pem" -o -name "*.key" -o -name "*.p12" -o -name "*.pfx" \) -print -quit 2>/dev/null | grep -q .; then
    WARNINGS+=("WARNING: Private key files detected in repository")
fi

# Warn if no monitoring
if [ ${#MONITORING_TOOLS[@]} -eq 0 ] && [ ${#IAC_TOOLS[@]} -gt 0 ]; then
    WARNINGS+=("No monitoring configuration detected - infrastructure without monitoring means outages go undetected")
fi

# Warn if no security scanning
if [ ${#SECURITY_TOOLS[@]} -eq 0 ] && [ ${#IAC_TOOLS[@]} -gt 0 ]; then
    WARNINGS+=("No IaC security scanning detected (tfsec, checkov, trivy) - consider adding infrastructure security scanning")
fi

# =============================================================================
# PLUGIN RECOMMENDATIONS
# =============================================================================

RECOMMENDED_PLUGINS=()

for tool in "${IAC_TOOLS[@]}"; do
    case "$tool" in
        "Terraform") RECOMMENDED_PLUGINS+=("terraform-patterns") ;;
        "Ansible") RECOMMENDED_PLUGINS+=("ansible-automation") ;;
        "Pulumi"|"CloudFormation"|"AWS CDK") RECOMMENDED_PLUGINS+=("aws-infrastructure") ;;
    esac
done

for provider in "${CLOUD_PROVIDERS[@]}"; do
    case "$provider" in
        "AWS") RECOMMENDED_PLUGINS+=("aws-infrastructure") ;;
        "GCP") RECOMMENDED_PLUGINS+=("gcp-infrastructure") ;;
        "Azure") RECOMMENDED_PLUGINS+=("azure-infrastructure") ;;
    esac
done

if [ "$HAS_DOCKER" = true ]; then RECOMMENDED_PLUGINS+=("docker-orchestration"); fi
if [ "$HAS_K8S" = true ] || [ "$HAS_HELM" = true ]; then RECOMMENDED_PLUGINS+=("kubernetes-operations"); fi

for ci in "${CI_SYSTEMS[@]}"; do
    case "$ci" in
        "GitHub Actions") RECOMMENDED_PLUGINS+=("github-actions") ;;
        "GitLab CI") RECOMMENDED_PLUGINS+=("gitlab-ci") ;;
        "Jenkins") RECOMMENDED_PLUGINS+=("jenkins-pipelines") ;;
    esac
done

if [ ${#MONITORING_TOOLS[@]} -gt 0 ]; then RECOMMENDED_PLUGINS+=("monitoring-observability"); fi
if [ ${#IAC_TOOLS[@]} -gt 0 ]; then
    RECOMMENDED_PLUGINS+=("secret-management")
    RECOMMENDED_PLUGINS+=("infrastructure-security")
fi

if [ ${#RECOMMENDED_PLUGINS[@]} -gt 0 ]; then
    UNIQUE_PLUGINS=$(printf '%s\n' "${RECOMMENDED_PLUGINS[@]}" | sort -u | tr '\n' ', ' | sed 's/,$//')
    INFRA_CONTEXT+=("Recommended LibreDevOps plugins: $UNIQUE_PLUGINS")
fi

# =============================================================================
# OUTPUT STRUCTURED RESPONSE
# =============================================================================

OUTPUT="{"

if [ ${#CONTEXT_MESSAGES[@]} -gt 0 ] || [ ${#INFRA_CONTEXT[@]} -gt 0 ]; then
    OUTPUT="$OUTPUT\"additionalContext\":["
    FIRST=true

    for msg in "${CONTEXT_MESSAGES[@]}"; do
        if [ "$FIRST" = true ]; then FIRST=false; else OUTPUT="$OUTPUT,"; fi
        ESCAPED_MSG=$(echo "$msg" | sed 's/"/\\"/g')
        OUTPUT="$OUTPUT{\"type\":\"text\",\"text\":\"$ESCAPED_MSG\"}"
    done

    for msg in "${INFRA_CONTEXT[@]}"; do
        if [ "$FIRST" = true ]; then FIRST=false; else OUTPUT="$OUTPUT,"; fi
        ESCAPED_MSG=$(echo "$msg" | sed 's/"/\\"/g')
        OUTPUT="$OUTPUT{\"type\":\"text\",\"text\":\"$ESCAPED_MSG\"}"
    done

    OUTPUT="$OUTPUT]"
fi

if [ ${#WARNINGS[@]} -gt 0 ]; then
    if [ ${#CONTEXT_MESSAGES[@]} -gt 0 ] || [ ${#INFRA_CONTEXT[@]} -gt 0 ]; then
        OUTPUT="$OUTPUT,"
    fi
    OUTPUT="$OUTPUT\"systemMessage\":\"LibreDevOps Infrastructure Assessment:\\n"
    for warn in "${WARNINGS[@]}"; do
        ESCAPED_WARN=$(echo "$warn" | sed 's/"/\\"/g')
        OUTPUT="$OUTPUT- $ESCAPED_WARN\\n"
    done
    OUTPUT="$OUTPUT\""
fi

OUTPUT="$OUTPUT}"

if [ ${#CONTEXT_MESSAGES[@]} -gt 0 ] || [ ${#INFRA_CONTEXT[@]} -gt 0 ] || [ ${#WARNINGS[@]} -gt 0 ]; then
    echo "$OUTPUT"
fi

# Log the detection summary
{
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Infrastructure Assessment for $PROJECT_NAME"
    echo "  IaC Tools: ${IAC_TOOLS[*]:-none}"
    echo "  CI/CD: ${CI_SYSTEMS[*]:-none}"
    echo "  Cloud Providers: ${CLOUD_PROVIDERS[*]:-none}"
    echo "  Docker: $HAS_DOCKER | K8s: $HAS_K8S | Helm: $HAS_HELM"
    echo "  Monitoring: ${MONITORING_TOOLS[*]:-none}"
    echo "  Security Tools: ${SECURITY_TOOLS[*]:-none}"
    echo "  State Backend: $HAS_STATE_BACKEND"
    echo "  Warnings: ${#WARNINGS[@]}"
    echo "---"
} >> "$HOOKS_LOG_DIR/sessions.log"

exit 0
