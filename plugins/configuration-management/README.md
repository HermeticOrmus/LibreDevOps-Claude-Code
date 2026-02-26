# Configuration Management Plugin

12-factor config, AWS SSM Parameter Store, Consul KV, feature flags (LaunchDarkly/Unleash), and config schema validation.

## Components

- **Agent**: `config-manager` -- Enforces secrets/config/code separation, designs SSM hierarchies, feature flag rollout strategies
- **Command**: `/config` -- Reads/writes SSM parameters, validates schemas, manages feature flag rollout
- **Skill**: `config-patterns` -- SSM hierarchy, IAM policies, Kubernetes ConfigMap, Unleash/LaunchDarkly patterns, Pydantic/Zod validation

## When to Use

- Deciding where a config value belongs (SSM, Consul, env var, ConfigMap, feature flag)
- Setting up AWS SSM Parameter Store hierarchy for multi-environment apps
- Implementing feature flags with percentage rollout and monitoring checkpoints
- Validating config schema at application startup (fail fast)
- Diffing config between environments to find missing parameters
- Setting up Consul Template for dynamic NGINX or application config

## Quick Reference

```bash
# SSM: Read all config for environment
aws ssm get-parameters-by-path \
  --path "/myapp/prod" --recursive --with-decryption \
  --output json | jq '.Parameters | map({(.Name): .Value}) | add'

# SSM: Write encrypted secret
aws ssm put-parameter \
  --name "/myapp/prod/stripe/api_key" \
  --value "$SECRET" \
  --type SecureString \
  --key-id "alias/myapp-prod" --overwrite

# Consul KV: read tree
consul kv get --recurse myapp/prod/

# Kubernetes: update ConfigMap + restart
kubectl patch configmap myapp-config -n production \
  --type merge -p '{"data":{"LOG_LEVEL":"debug"}}'
kubectl rollout restart deployment/myapp -n production
```

## Config Classification

| Type | Where it lives | Example |
|------|---------------|---------|
| Secret (rotatable) | AWS Secrets Manager | DB password |
| Secret (static) | SSM SecureString | API key |
| Config (env-specific) | SSM String | DB host, pool size |
| Config (shared) | Consul KV | Rate limits, timeouts |
| Feature flag | LaunchDarkly / Unleash | New UI flow |
| Cluster config | Kubernetes ConfigMap | App settings |
| Code defaults | Application code | Default timeout |

## Key Principles

**12-Factor III**: Config = anything that varies between environments. It belongs in the environment, not the source tree.

**Fail fast on startup**: Validate required config with schema validation (Pydantic, Zod) before accepting traffic. A missing config discovered under load is a worse outage than one caught at startup.

**Never log secret values**: Log config keys and types, not values. Include redaction in your logging setup.

**Feature flags decouple deploy from release**: Ship dark-launched code, enable incrementally, use as kill switch. Remove flag and dead code after full rollout.

## Related Plugins

- [secret-management](../secret-management/) -- HashiCorp Vault for dynamic secrets and rotation
- [kubernetes-operations](../kubernetes-operations/) -- ConfigMaps, Secrets, External Secrets Operator
- [monitoring-observability](../monitoring-observability/) -- Alerting on config-driven error rates during rollout
- [ansible-automation](../ansible-automation/) -- Ansible Vault for config file management
