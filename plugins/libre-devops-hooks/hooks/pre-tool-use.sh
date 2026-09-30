#!/usr/bin/env bash
# =============================================================================
# LibreDevOps PreToolUse hook (Edit, Write, MultiEdit)
# =============================================================================
# Before Claude edits a file that holds state or secrets, ask the user first:
#   - Terraform state (*.tfstate, *.tfstate.backup, *.tfstate.*)
#   - cloud credential files (credentials, credentials.json, service-account*.json)
#   - Ansible Vault password files (vault_password_file, .vault_pass)
#   - environment files (.env, .env.*; templates such as .env.example are fine)
#   - private keys and keystores (*.pem, *.key, *.p12, *.pfx, *.jks, id_rsa, ...)
#   - config and data files named after secrets (secrets.yaml, secret.tfvars, ...)
#
# Every other edit passes through silently. The infrastructure checks that
# used to print here now run after the edit, in post-tool-use.sh.
#
# Input:  hook JSON on stdin (tool_name, tool_input.file_path)
# Output: a PreToolUse "ask" decision on stdout for sensitive paths, else nothing
# Needs:  jq (exits silently without it)
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

command -v jq >/dev/null 2>&1 || exit 0

INPUT="$(cat || true)"
TOOL="$(jq -r '.tool_name // empty' <<<"$INPUT" 2>/dev/null || true)"
FILE="$(jq -r '.tool_input.file_path // empty' <<<"$INPUT" 2>/dev/null || true)"

case "$TOOL" in Edit|Write|MultiEdit) ;; *) exit 0 ;; esac
[[ -n "$FILE" ]] || exit 0

NAME="$(basename "$FILE" | tr '[:upper:]' '[:lower:]')"
REASON=""

if [[ "$NAME" =~ \.tfstate$ || "$NAME" =~ \.tfstate\. ]]; then
  REASON="LibreDevOps: $NAME is Terraform state. Editing it by hand can corrupt state; prefer terraform state mv, terraform state rm, or terraform import."
elif [[ "$NAME" =~ ^(credentials|credentials\.json|service-account.*\.json)$ ]]; then
  REASON="LibreDevOps: $NAME is a credential file. Prefer a secret manager (AWS Secrets Manager, Vault, GCP Secret Manager) over editing credentials in place."
elif [[ "$NAME" =~ ^(vault_password_file|\.vault_pass(\.txt)?)$ ]]; then
  REASON="LibreDevOps: $NAME is an Ansible Vault password file. Manage vault passwords by hand, outside generated edits."
elif [[ "$NAME" =~ ^\.env(\..+)?$ && ! "$NAME" =~ \.(example|sample|template|dist)$ ]]; then
  REASON="LibreDevOps: $NAME is an environment file that may hold secrets. Keep it out of git and use a secret manager for production values."
elif [[ "$NAME" =~ \.(pem|key|p12|pfx|jks|keystore)$ || "$NAME" =~ ^id_(rsa|ecdsa|ed25519|dsa)$ ]]; then
  REASON="LibreDevOps: $NAME looks like a private key or keystore. Keys belong in a secret manager or certificate store, not in the working tree."
elif [[ "$NAME" =~ (^|[._-])secrets?([._-]|$) ]] \
  && [[ "$NAME" != *.* || "$NAME" =~ \.(ya?ml|json|tfvars|env|toml|ini|conf|properties|txt)$ ]]; then
  REASON="LibreDevOps: $NAME looks like a secrets file. Confirm it is encrypted (SOPS, Sealed Secrets, Ansible Vault) or excluded from git before editing."
fi

[[ -n "$REASON" ]] || exit 0

jq -n --arg reason "$REASON" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "ask",
    permissionDecisionReason: $reason
  }
}'
exit 0
