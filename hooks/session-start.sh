#!/bin/bash
# Session Start Hook - DevOps
# Detects project context: IaC tools, cloud providers, CI/CD platforms, containers

LOG_DIR="$(dirname "$0")/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/session-$(date +%Y%m%d-%H%M%S).log"

log() {
  echo "[$(date +%H:%M:%S)] $1" >> "$LOG_FILE"
}

log "Session started"
log "Working directory: $(pwd)"

CONTEXT_ITEMS=()

# --- IaC Detection ---

if find . -maxdepth 3 -name "*.tf" -type f 2>/dev/null | head -1 | grep -q .; then
  TF_INFO="Terraform files detected"
  if command -v terraform &>/dev/null; then
    TF_VER=$(terraform version -json 2>/dev/null | grep -o '"terraform_version":"[^"]*"' | cut -d'"' -f4 || true)
    [ -n "$TF_VER" ] && TF_INFO="$TF_INFO (v$TF_VER)"
  fi
  CONTEXT_ITEMS+=("$TF_INFO")

  if grep -rl 'backend "' . --include="*.tf" 2>/dev/null | head -1 | grep -q .; then
    BACKEND=$(grep -rh 'backend "' . --include="*.tf" 2>/dev/null | head -1 | sed 's/.*backend "\([^"]*\)".*/\1/')
    CONTEXT_ITEMS+=("  State backend: $BACKEND")
  else
    CONTEXT_ITEMS+=("  WARNING: No remote state backend configured")
  fi
fi

if find . -maxdepth 3 -name "Pulumi.yaml" -type f 2>/dev/null | head -1 | grep -q .; then
  CONTEXT_ITEMS+=("Pulumi project detected")
fi

# --- Ansible Detection ---

if [ -f "ansible.cfg" ] || find . -maxdepth 3 -name "playbook*.yml" -type f 2>/dev/null | head -1 | grep -q .; then
  CONTEXT_ITEMS+=("Ansible project detected")
fi

# --- Container Detection ---

if find . -maxdepth 3 -name "Dockerfile*" -type f 2>/dev/null | head -1 | grep -q .; then
  DCOUNT=$(find . -maxdepth 3 -name "Dockerfile*" -type f 2>/dev/null | wc -l)
  CONTEXT_ITEMS+=("Docker: $DCOUNT Dockerfile(s)")
fi

if find . -maxdepth 2 \( -name "docker-compose*.yml" -o -name "compose*.yml" \) -type f 2>/dev/null | head -1 | grep -q .; then
  CONTEXT_ITEMS+=("Docker Compose detected")
fi

# --- Kubernetes Detection ---

if find . -maxdepth 3 -name "Chart.yaml" -type f 2>/dev/null | head -1 | grep -q .; then
  HCOUNT=$(find . -maxdepth 3 -name "Chart.yaml" -type f 2>/dev/null | wc -l)
  CONTEXT_ITEMS+=("Helm: $HCOUNT chart(s)")
fi

if find . -maxdepth 3 -name "kustomization.yaml" -type f 2>/dev/null | head -1 | grep -q .; then
  CONTEXT_ITEMS+=("Kustomize detected")
fi

if [ -d "k8s/" ] || [ -d "kubernetes/" ]; then
  CONTEXT_ITEMS+=("Kubernetes manifests directory found")
fi

# --- Cloud Provider Detection ---

if find . -maxdepth 3 -name "*.tf" -type f 2>/dev/null | xargs grep -l 'provider "aws"' 2>/dev/null | head -1 | grep -q .; then
  CONTEXT_ITEMS+=("Cloud: AWS")
fi

if find . -maxdepth 3 -name "*.tf" -type f 2>/dev/null | xargs grep -l 'provider "google"' 2>/dev/null | head -1 | grep -q .; then
  CONTEXT_ITEMS+=("Cloud: GCP")
fi

if find . -maxdepth 3 -name "*.tf" -type f 2>/dev/null | xargs grep -l 'provider "azurerm"' 2>/dev/null | head -1 | grep -q .; then
  CONTEXT_ITEMS+=("Cloud: Azure")
fi

# --- CI/CD Detection ---

if [ -d ".github/workflows" ]; then
  WCOUNT=$(find .github/workflows -name "*.yml" -o -name "*.yaml" 2>/dev/null | wc -l)
  CONTEXT_ITEMS+=("CI/CD: GitHub Actions ($WCOUNT workflows)")
fi

[ -f ".gitlab-ci.yml" ] && CONTEXT_ITEMS+=("CI/CD: GitLab CI")
[ -f "Jenkinsfile" ] && CONTEXT_ITEMS+=("CI/CD: Jenkins")
[ -f ".circleci/config.yml" ] && CONTEXT_ITEMS+=("CI/CD: CircleCI")

# --- Security Warnings ---

if find . -maxdepth 2 -name ".env" -type f 2>/dev/null | head -1 | grep -q .; then
  CONTEXT_ITEMS+=("WARNING: .env file found -- verify it is in .gitignore")
fi

if find . -maxdepth 3 \( -name "*.pem" -o -name "*.key" \) -type f 2>/dev/null | head -1 | grep -q .; then
  CONTEXT_ITEMS+=("WARNING: Private key files detected")
fi

# --- Monitoring Detection ---

if find . -maxdepth 3 -name "prometheus*.yml" -type f 2>/dev/null | head -1 | grep -q .; then
  CONTEXT_ITEMS+=("Monitoring: Prometheus config found")
fi

# --- Output ---

if [ ${#CONTEXT_ITEMS[@]} -gt 0 ]; then
  echo "=== Infrastructure Context ==="
  for item in "${CONTEXT_ITEMS[@]}"; do
    echo "  $item"
  done
  echo "==============================="
  log "Context items: ${#CONTEXT_ITEMS[@]}"
else
  echo "[DevOps] No infrastructure files detected."
  log "No infrastructure context found"
fi

# Check for project-specific configuration
[ -f "CLAUDE.md" ] && log "Found project CLAUDE.md"
[ -f ".claude/settings.json" ] && log "Found Claude settings"

log "Session start hook complete"
