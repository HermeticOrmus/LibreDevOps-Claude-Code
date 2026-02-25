#!/bin/bash
# Pre-Tool-Use Hook - DevOps
# IaC validation and secret scanning before file operations

TOOL_NAME="${1:-unknown}"
TARGET="${2:-}"

# Skip if no target
[ -z "$TARGET" ] && exit 0

BASENAME=$(basename "$TARGET")
EXTENSION="${BASENAME##*.}"

# --- State File Protection ---

if [[ "$BASENAME" == "terraform.tfstate" ]] || [[ "$BASENAME" == *.tfstate ]] || [[ "$BASENAME" == *.tfstate.backup ]]; then
  echo "BLOCKED: Direct modification of Terraform state files. Use 'terraform state' commands."
  exit 1
fi

# --- Credential File Protection ---

if [[ "$BASENAME" == "credentials" ]] || [[ "$BASENAME" == "credentials.json" ]] || \
   [[ "$BASENAME" == "service-account.json" ]] || [[ "$BASENAME" == "service-account-key.json" ]]; then
  echo "BLOCKED: Direct modification of credential files. Use a secret manager."
  exit 1
fi

if [[ "$BASENAME" == "vault_password_file" ]] || [[ "$BASENAME" == ".vault_pass" ]]; then
  echo "BLOCKED: Ansible vault password files must never be committed."
  exit 1
fi

# --- Sensitive File Warnings ---

check_sensitive_files() {
  if echo "$TARGET" | grep -qiE '\.(env|key|pem|credentials|secret|p12|pfx)$'; then
    echo "WARNING: Operation targets potentially sensitive file: $TARGET"
    return 1
  fi
  return 0
}

check_destructive_ops() {
  if echo "$TOOL_NAME" | grep -qiE '(delete|remove|drop|destroy|force)'; then
    echo "CAUTION: Destructive operation detected: $TOOL_NAME on $TARGET"
    return 1
  fi
  return 0
}

# --- Terraform Secret Scanning ---

if [[ "$EXTENSION" == "tf" ]] || [[ "$EXTENSION" == "tfvars" ]]; then
  if [ -f "$TARGET" ]; then
    if grep -qE 'AKIA[0-9A-Z]{16}' "$TARGET" 2>/dev/null; then
      echo "BLOCKED: AWS Access Key ID detected in Terraform file. Use IAM roles."
      exit 1
    fi
    if grep -qiE '(password|secret|token)\s*=\s*"[^${}]' "$TARGET" 2>/dev/null; then
      echo "WARNING: Possible hardcoded secret in Terraform file."
    fi
    if grep -qE 'cidr_blocks.*=.*\["0\.0\.0\.0/0"\]' "$TARGET" 2>/dev/null; then
      echo "WARNING: Security group open to 0.0.0.0/0 detected. Restrict access."
    fi
  fi
fi

# --- Kubernetes Secret Scanning ---

if [[ "$EXTENSION" == "yaml" ]] || [[ "$EXTENSION" == "yml" ]]; then
  if [ -f "$TARGET" ]; then
    if grep -q "kind: Secret" "$TARGET" 2>/dev/null; then
      echo "WARNING: Kubernetes Secret manifest. Use External Secrets Operator or sealed-secrets."
    fi
    if grep -q "privileged: true" "$TARGET" 2>/dev/null; then
      echo "WARNING: Privileged container detected. Verify this is intentional."
    fi
  fi
fi

# --- Dockerfile Checks ---

if [[ "$BASENAME" == "Dockerfile" ]] || [[ "$BASENAME" == Dockerfile.* ]]; then
  if [ -f "$TARGET" ]; then
    if grep -qiE 'ARG.*(password|secret|token|key)' "$TARGET" 2>/dev/null; then
      echo "WARNING: Build ARG may contain secrets. Use runtime injection instead."
    fi
  fi
fi

# --- CI/CD Token Scanning ---

if [[ "$TARGET" == *".github/workflows/"* ]] || [[ "$BASENAME" == ".gitlab-ci.yml" ]]; then
  if [ -f "$TARGET" ]; then
    if grep -qE '(ghp_|gho_|github_pat_|glpat-)[a-zA-Z0-9]' "$TARGET" 2>/dev/null; then
      echo "BLOCKED: Token detected in CI config. Use repository secrets."
      exit 1
    fi
  fi
fi

# Run general checks
check_sensitive_files
check_destructive_ops

exit 0
