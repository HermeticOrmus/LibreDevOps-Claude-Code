# Secret Management Plugin

HashiCorp Vault, External Secrets Operator (ESO), SOPS, Sealed Secrets, AWS Secrets Manager, and automatic secret rotation.

## Components

- **Agent**: `secrets-engineer` -- Dynamic secrets with Vault, ESO sync patterns, SOPS GitOps workflow, zero-downtime rotation
- **Command**: `/secrets` -- Reads/writes secrets across backends, triggers rotation, audits access
- **Skill**: `secrets-patterns` -- Vault Agent injector annotations, ESO with Vault/AWS, Sealed Secrets workflow, IRSA for ESO, rotating connection pool pattern

## Quick Reference

```bash
# Vault: read dynamic DB credentials
vault read database/creds/app-readwrite

# Vault: write application secret
vault kv put secret/production/myapp api_key="value" db_pass="value"

# ESO: force re-sync from source
kubectl annotate externalsecret myapp-secrets force-sync=$(date +%s) --overwrite -n production

# Secrets Manager: trigger rotation
aws secretsmanager rotate-secret --secret-id production/myapp/db --rotate-immediately

# Find hardcoded secrets in codebase
gitleaks detect --source=. --verbose
```

## Security Rules

1. **Never commit plaintext secrets** -- Use SOPS, Sealed Secrets, or reference a secret manager
2. **Kubernetes Secrets are NOT encrypted by default** -- Only base64-encoded. Enable encryption at rest or use ESO/Vault Agent
3. **Prefer dynamic credentials** -- Vault database engine > static passwords with rotation
4. **Least privilege** -- Vault policies per role, not shared. IAM policy for ESO limited to its namespace's secrets
5. **Audit access** -- Enable Vault audit log and CloudTrail for Secrets Manager. Alert on unexpected GetSecretValue calls

## Secret Store Decision

| Need | Solution |
|------|----------|
| Dynamic DB credentials | Vault database engine |
| AWS-native, simple rotation | AWS Secrets Manager |
| Secrets in Kubernetes (GitOps) | Sealed Secrets (cluster-bound) or SOPS + ESO |
| Multi-cloud, PKI, SSH certs | HashiCorp Vault |
| Pull secrets to Kubernetes | External Secrets Operator (works with all backends) |

## Related Plugins

- [infrastructure-security](../infrastructure-security/) -- Vault PKI, secret scanning
- [configuration-management](../configuration-management/) -- App config vs secrets separation
- [kubernetes-operations](../kubernetes-operations/) -- ServiceAccount for Vault auth
- [aws-infrastructure](../aws-infrastructure/) -- IRSA for Secrets Manager access
