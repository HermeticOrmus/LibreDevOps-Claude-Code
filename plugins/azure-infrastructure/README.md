# Azure Infrastructure Plugin

Azure Bicep/ARM, AKS, App Service, Azure DevOps pipelines, Key Vault, and landing zone governance patterns.

## Components

- **Agent**: `azure-architect` -- Designs Bicep modules, AKS workload identity, Key Vault integration, Azure Policy governance
- **Command**: `/azure` -- Deploys Bicep, configures managed identity federation, creates pipelines, applies governance
- **Skill**: `azure-patterns` -- Bicep module structure, AKS workload identity, App Service KV references, Private Endpoints

## When to Use

- Writing Bicep modules for Azure resources (VNets, AKS, SQL, App Service, Key Vault)
- Configuring AKS workload identity for pod-level Azure authentication (no secrets)
- Setting up Azure DevOps pipelines with approval gates and Key Vault variable groups
- Applying Azure Policy and Defender for Cloud governance
- Designing hub-spoke networks with Private Endpoints for PaaS services
- Landing zone subscription vending and management group hierarchy

## Quick Reference

```bash
# Deploy Bicep with what-if preview
az deployment group what-if \
  --resource-group rg-prod \
  --template-file infra/main.bicep \
  --parameters @infra/environments/prod.bicepparam

# Configure AKS workload identity
az aks show --name aks-prod --resource-group rg-prod \
  --query oidcIssuerProfile.issuerURL -o tsv

# Check policy compliance
az policy state summarize --subscription $SUBSCRIPTION_ID \
  --query "results.policyAssignments[?results.nonCompliantResources > \`0\`]"

# Enable Defender for Cloud
az security pricing create --name KubernetesService --tier Standard
```

## Key Concepts

**Bicep vs ARM**: Bicep is the preferred authoring language -- cleaner syntax, compiles to ARM JSON, native Azure tooling. Use `az bicep` CLI. Decompile existing ARM templates with `az bicep decompile`.

**Managed Identity vs Service Principal**: Always prefer managed identity (system or user-assigned). No credentials to rotate, no secrets in code. Use workload identity federation for Kubernetes pods.

**Key Vault References in App Service**: App Settings can reference Key Vault secrets directly with `@Microsoft.KeyVault(SecretUri=...)` syntax. The App Service managed identity needs Key Vault Secrets User role. Secrets never pass through App Service's config plane.

**AKS Workload Identity**: Replace pod service account secrets with federated credentials. AKS OIDC Issuer issues tokens that Azure AD trusts. App uses `DefaultAzureCredential` from Azure SDK -- no configuration needed.

**Private Endpoints**: PaaS services (SQL, Storage, Key Vault, ACR) should use Private Endpoints in production. Disable public access. Pair with Private DNS Zones for proper name resolution within VNets.

## Related Plugins

- [kubernetes-operations](../kubernetes-operations/) -- AKS workload management, Helm, kubectl
- [secret-management](../secret-management/) -- HashiCorp Vault as alternative to Key Vault
- [infrastructure-security](../infrastructure-security/) -- Checkov scanning for Bicep/ARM
- [github-actions](../github-actions/) -- GitHub Actions OIDC for Azure deployments
- [terraform-patterns](../terraform-patterns/) -- Terraform azurerm provider alternative
