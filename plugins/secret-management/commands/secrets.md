# /secrets

Manage secrets in Vault, AWS Secrets Manager, and Kubernetes using ESO and Sealed Secrets.

## Usage

```
/secrets read|write|rotate|audit [options]
```

## Actions

### `read`
Read secrets from various backends.

```bash
# Vault: read a secret
vault kv get secret/production/payment-api

# Vault: read as JSON
vault kv get -format=json secret/production/payment-api | jq '.data.data'

# Vault: get dynamic database credentials
vault read database/creds/app-readwrite

# Vault: check secret metadata (version history, creation time)
vault kv metadata get secret/production/payment-api

# AWS Secrets Manager: read a secret
aws secretsmanager get-secret-value \
  --secret-id production/payment-api/database \
  --query 'SecretString' --output text | jq .

# AWS Secrets Manager: list secrets
aws secretsmanager list-secrets \
  --filter Key=name,Values=production/ \
  --query 'SecretList[*].{Name:Name,LastRotated:LastRotatedDate}' \
  --output table

# Kubernetes: decode a secret (base64)
kubectl get secret payment-api-secrets -n production -o jsonpath='{.data}' | \
  jq 'to_entries[] | {key: .key, value: (.value | @base64d)}'

# Check ESO sync status
kubectl get externalsecret -n production
kubectl describe externalsecret payment-api-secrets -n production
```

### `write`
Create and update secrets.

```bash
# Vault: write a secret (KV v2)
vault kv put secret/production/payment-api \
  stripe_secret_key="sk_live_xxxx" \
  sendgrid_api_key="SG.xxxx"

# Vault: patch (update only specified keys, preserve others)
vault kv patch secret/production/payment-api \
  stripe_secret_key="sk_live_new_value"

# Vault: write from a file
vault kv put secret/production/payment-api @secrets.json

# AWS Secrets Manager: create a secret
aws secretsmanager create-secret \
  --name production/payment-api/stripe \
  --secret-string '{"secret_key":"sk_live_xxx"}' \
  --kms-key-id alias/prod-secrets-key \
  --tags Key=Environment,Value=production Key=Service,Value=payment-api

# AWS Secrets Manager: update secret value
aws secretsmanager update-secret \
  --secret-id production/payment-api/stripe \
  --secret-string '{"secret_key":"sk_live_new_xxx"}'

# SOPS: encrypt and commit a secret
sops --encrypt secrets.yaml > secrets.enc.yaml
git add secrets.enc.yaml && git commit -m "chore: update API key"

# Create Kubernetes Secret for manual use
kubectl create secret generic myapp-secret \
  --from-literal=API_KEY="$API_KEY" \
  --from-literal=DB_PASSWORD="$DB_PASSWORD" \
  -n production --dry-run=client -o yaml | kubectl apply -f -
```

### `rotate`
Rotate credentials and verify rotation.

```bash
# AWS Secrets Manager: trigger immediate rotation
aws secretsmanager rotate-secret \
  --secret-id production/payment-api/database \
  --rotate-immediately

# Check rotation status
aws secretsmanager describe-secret \
  --secret-id production/payment-api/database \
  --query '{RotationEnabled:RotationEnabled,LastRotatedDate:LastRotatedDate,RotationRules:RotationRules}'

# Vault: revoke all leases for a role (force rotation)
vault lease revoke -prefix database/creds/app-readwrite

# Vault: renew a lease (extend before expiry)
vault lease renew $LEASE_ID

# Vault: rotate root credentials (change what Vault uses to manage DB)
vault write -force database/rotate-root/postgres

# ESO: force re-sync (picks up rotated secret immediately)
kubectl annotate externalsecret payment-api-secrets \
  force-sync=$(date +%s) \
  --overwrite -n production

# Verify K8s secret updated after ESO sync
kubectl get secret payment-api-secrets -n production -o jsonpath='{.metadata.annotations.reconcile\.external-secrets\.io/data-hash}'

# Test new credentials work before marking rotation complete
# (application-specific test)
kubectl run -it --rm secret-test --image=postgres:15 --restart=Never -- \
  psql "postgresql://$NEW_USER:$NEW_PASS@postgres.internal/myapp" -c "SELECT 1;"
```

### `audit`
Audit secret access and find leaked secrets.

```bash
# Vault: list auth tokens and their policies
vault list auth/token/accessors | xargs -I {} vault token lookup -accessor {}

# Vault: audit log (requires audit device configured)
vault audit enable file file_path=/vault/logs/audit.log

# AWS Secrets Manager: check who accessed a secret
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=GetSecretValue \
  --start-time $(date -d '-24h' -u +%Y-%m-%dT%H:%M:%SZ) | \
  jq '.Events[] | {user: .Username, secret: .CloudTrailEvent | fromjson | .requestParameters.secretId, time: .EventTime}'

# Find secrets hardcoded in code (pre-commit check)
gitleaks detect --source=. --verbose

# Scan for secrets in Git history
gitleaks detect --source=. --log-opts="--all" > gitleaks-report.json

# Check for K8s Secrets with data that looks like passwords
kubectl get secrets -A -o json | \
  jq '.items[] | select(.type=="Opaque") | {name: .metadata.name, namespace: .metadata.namespace, keys: (.data // {} | keys)}'

# List ESO external secrets and their last sync time
kubectl get externalsecret -A -o json | \
  jq '.items[] | {name: .metadata.name, ns: .metadata.namespace, status: .status.conditions[-1].type, lastSync: .status.refreshTime}'
```
