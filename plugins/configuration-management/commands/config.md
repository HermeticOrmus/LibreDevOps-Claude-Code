# /config

Read, write, validate, and roll out configuration and feature flags across environments.

## Usage

```
/config read|write|validate|rollout [options]
```

## Actions

### `read`
Read configuration from SSM, Consul, or Kubernetes ConfigMaps.

```bash
# SSM: Read all config for an environment
aws ssm get-parameters-by-path \
  --path "/myapp/prod" \
  --recursive \
  --with-decryption \
  --output json | jq '.Parameters | map({(.Name): .Value}) | add'

# SSM: Read single parameter
aws ssm get-parameter \
  --name "/myapp/prod/database/url" \
  --with-decryption \
  --query 'Parameter.Value' \
  --output text

# Consul KV: Read config value
consul kv get myapp/prod/feature/new-checkout

# Consul KV: Read entire config tree
consul kv get --recurse myapp/prod/

# Kubernetes ConfigMap
kubectl get configmap myapp-config -n production -o yaml
kubectl get configmap myapp-config -n production \
  -o jsonpath='{.data}' | jq .

# Diff config between environments
diff \
  <(aws ssm get-parameters-by-path --path /myapp/staging --recursive --with-decryption | jq '.Parameters | sort_by(.Name)') \
  <(aws ssm get-parameters-by-path --path /myapp/prod --recursive --with-decryption | jq '.Parameters | sort_by(.Name)')
```

### `write`
Write configuration securely.

```bash
# SSM: Write encrypted parameter
aws ssm put-parameter \
  --name "/myapp/prod/stripe/api_key" \
  --value "$STRIPE_API_KEY" \
  --type SecureString \
  --key-id "alias/myapp-prod" \
  --overwrite

# SSM: Bulk write from JSON file
cat config.json | jq -r '
  to_entries[] |
  "aws ssm put-parameter --name \"/myapp/prod/\(.key)\" --value \"\(.value)\" --type String --overwrite"
' | bash

# Consul KV: Write
consul kv put myapp/prod/max-connections 100
consul kv put myapp/prod/feature/new-checkout false

# Kubernetes: Update ConfigMap and trigger rolling restart
kubectl create configmap myapp-config \
  --from-env-file=config.prod.env \
  --dry-run=client -o yaml | kubectl apply -f -
kubectl rollout restart deployment/myapp -n production

# Kubernetes: Update single value in ConfigMap
kubectl patch configmap myapp-config -n production \
  --type merge \
  -p '{"data":{"LOG_LEVEL":"debug"}}'
```

### `validate`
Validate configuration schema and environment completeness.

```bash
# Compare expected config keys vs what's in SSM
REQUIRED_KEYS="database/url redis/url jwt_secret stripe/api_key"
ENVIRONMENT="prod"

for key in $REQUIRED_KEYS; do
  if aws ssm get-parameter \
    --name "/myapp/${ENVIRONMENT}/${key}" \
    --with-decryption > /dev/null 2>&1; then
    echo "OK: /myapp/${ENVIRONMENT}/${key}"
  else
    echo "MISSING: /myapp/${ENVIRONMENT}/${key}"
  fi
done

# Validate config schema in CI (Node.js example)
node -e "
  require('dotenv').config({ path: '.env.test' });
  const { config } = require('./src/config');
  console.log('Config valid:', JSON.stringify(config, null, 2));
"

# Python Pydantic validation
python -c "
from app.config import Settings
s = Settings()
print('Config OK:', s.dict())
"
```

### `rollout`
Manage feature flag rollout with monitoring checkpoints.

```bash
# LaunchDarkly: Enable flag for internal users only via API
curl -X PATCH \
  "https://app.launchdarkly.com/api/v2/flags/production/new-checkout-flow" \
  -H "Authorization: $LD_API_KEY" \
  -H "Content-Type: application/json; domain-model=launchdarkly.semanticpatch" \
  --data '{
    "instructions": [
      {
        "kind": "addTargets",
        "variationId": "true-variation-id",
        "values": ["user-123", "user-456"]
      }
    ]
  }'

# Unleash: Gradual rollout via API
curl -X PUT \
  "https://unleash.example.com/api/admin/projects/default/features/new-checkout-flow/environments/production/strategies/STRATEGY_ID" \
  -H "Authorization: $UNLEASH_ADMIN_KEY" \
  -H "Content-Type: application/json" \
  --data '{
    "name": "gradualRolloutUserId",
    "parameters": {
      "percentage": "25",
      "groupId": "new-checkout-flow"
    }
  }'

# Monitor error rates before increasing rollout %
# Check: error rate, p99 latency, conversion rate
watch -n 30 'kubectl exec -n monitoring deploy/prometheus -- \
  promtool query instant http://localhost:9090 \
  "rate(http_requests_total{status=~\"5..\",feature=\"new-checkout\"}[5m])"'
```

## Environment Config Promotion

```bash
# Promote staging config to prod (with review)
#!/bin/bash
SOURCE_ENV="staging"
TARGET_ENV="prod"

# Get all staging parameters
STAGING_PARAMS=$(aws ssm get-parameters-by-path \
  --path "/myapp/${SOURCE_ENV}" \
  --recursive \
  --with-decryption \
  --output json | jq -c '.Parameters[]')

# Show diff and prompt for each
while IFS= read -r param; do
  name=$(echo "$param" | jq -r '.Name')
  value=$(echo "$param" | jq -r '.Value')
  prod_name="${name/$SOURCE_ENV/$TARGET_ENV}"

  echo "Promote: $name -> $prod_name"
  echo "Value: $value"
  read -p "Promote this config? [y/N]: " confirm

  if [[ "$confirm" == "y" ]]; then
    aws ssm put-parameter \
      --name "$prod_name" \
      --value "$value" \
      --type "$(echo "$param" | jq -r '.Type')" \
      --overwrite
    echo "Written: $prod_name"
  fi
done <<< "$STAGING_PARAMS"
```
