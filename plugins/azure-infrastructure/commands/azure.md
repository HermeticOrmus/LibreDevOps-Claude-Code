# /azure

Provision Azure infrastructure with Bicep, configure identity, design pipelines, and enforce governance.

## Usage

```
/azure provision|identity|pipeline|govern [options]
```

## Actions

### `provision`
Generate Bicep modules for Azure resources.

```bash
# Deploy Bicep to resource group
az deployment group create \
  --resource-group rg-prod-app \
  --template-file infra/main.bicep \
  --parameters infra/environments/prod.bicepparam \
  --confirm-with-what-if

# Preview changes (what-if)
az deployment group what-if \
  --resource-group rg-prod-app \
  --template-file infra/main.bicep \
  --parameters @infra/environments/prod.bicepparam

# Deploy to subscription scope (creates resource groups)
az deployment sub create \
  --location eastus2 \
  --template-file infra/main.bicep \
  --parameters environment=prod

# Validate template syntax
az bicep build --file infra/main.bicep  # Compile to ARM JSON
az deployment group validate \
  --resource-group rg-prod-app \
  --template-file infra/main.bicep
```

```bicep
// AKS cluster with autoscaling and zone redundancy
resource aks 'Microsoft.ContainerService/managedClusters@2023-10-01' = {
  name: 'aks-${environment}'
  location: location
  identity: { type: 'SystemAssigned' }
  properties: {
    dnsPrefix: 'aks-${environment}'
    enableRBAC: true
    oidcIssuerProfile: { enabled: true }
    securityProfile: { workloadIdentity: { enabled: true } }
    agentPoolProfiles: [
      {
        name: 'system'
        count: 3
        vmSize: 'Standard_D4ds_v5'
        mode: 'System'
        availabilityZones: ['1', '2', '3']
        enableAutoScaling: true
        minCount: 3
        maxCount: 10
        osDiskType: 'Ephemeral'  // Better IOPS, no extra cost
        nodeTaints: ['CriticalAddonsOnly=true:NoSchedule']
      }
      {
        name: 'user'
        count: 2
        vmSize: 'Standard_D8ds_v5'
        mode: 'User'
        availabilityZones: ['1', '2', '3']
        enableAutoScaling: true
        minCount: 1
        maxCount: 50
        osDiskType: 'Ephemeral'
      }
    ]
  }
}
```

### `identity`
Configure managed identity and workload identity federation.

```bash
# Create user-assigned managed identity
az identity create \
  --name id-myapp-prod \
  --resource-group rg-prod-app

# Get identity details for federation
IDENTITY_CLIENT_ID=$(az identity show \
  --name id-myapp-prod \
  --resource-group rg-prod-app \
  --query clientId -o tsv)

IDENTITY_PRINCIPAL_ID=$(az identity show \
  --name id-myapp-prod \
  --resource-group rg-prod-app \
  --query principalId -o tsv)

# Grant Key Vault Secrets User role
az role assignment create \
  --assignee "$IDENTITY_PRINCIPAL_ID" \
  --role "Key Vault Secrets User" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/rg-prod/providers/Microsoft.KeyVault/vaults/kv-prod"

# Create federated credential (trust AKS service account)
AKS_OIDC=$(az aks show \
  --name aks-prod \
  --resource-group rg-prod-app \
  --query oidcIssuerProfile.issuerURL -o tsv)

az identity federated-credential create \
  --name myapp-k8s-fedcred \
  --identity-name id-myapp-prod \
  --resource-group rg-prod-app \
  --issuer "$AKS_OIDC" \
  --subject "system:serviceaccount:myapp:myapp-sa" \
  --audience api://AzureADTokenExchange
```

### `pipeline`
Create Azure DevOps pipelines with approval gates and Key Vault integration.

```bash
# Create variable group linked to Key Vault
az pipelines variable-group create \
  --name myapp-prod-secrets \
  --authorize true \
  --variables "placeholder=value" \
  --description "Linked to Key Vault"

# Link variable group to Key Vault (done in Azure DevOps UI or API)
# API: PATCH https://dev.azure.com/{org}/{project}/_apis/distributedtask/variablegroups/{id}

# Create environment with approval
az devops invoke \
  --area distributedtask \
  --resource environments \
  --route-parameters project=MyProject \
  --http-method POST \
  --in-file environment-def.json
```

### `govern`
Apply Azure Policy, Defender for Cloud, and governance controls.

```bash
# Enable Defender for Cloud (all plans)
az security pricing create --name VirtualMachines --tier Standard
az security pricing create --name ContainerRegistry --tier Standard
az security pricing create --name KubernetesService --tier Standard
az security pricing create --name AppServices --tier Standard
az security pricing create --name SqlServers --tier Standard

# Assign CIS Azure Benchmark initiative
az policy assignment create \
  --name cis-azure-benchmark \
  --display-name "CIS Azure Foundations Benchmark" \
  --policy-set-definition "06f19060-9e68-4070-92ca-f15cc126059e" \
  --scope "/subscriptions/$SUBSCRIPTION_ID" \
  --identity-scope "/subscriptions/$SUBSCRIPTION_ID" \
  --role Contributor \
  --location eastus2

# Check policy compliance state
az policy state summarize \
  --subscription "$SUBSCRIPTION_ID" \
  --query "results.policyAssignments[].{Policy:policyAssignmentId,NonCompliant:results.nonCompliantResources}"

# List non-compliant resources
az policy state list \
  --subscription "$SUBSCRIPTION_ID" \
  --filter "complianceState eq 'NonCompliant'" \
  --query "[].{Resource:resourceId,Policy:policyDefinitionName}" \
  --output table
```

## Bicep Reference Commands

```bash
# Install/upgrade Bicep CLI
az bicep install
az bicep upgrade

# Decompile ARM JSON to Bicep (migration)
az bicep decompile --file template.json

# Generate parameter file from template
az bicep generate-params --file main.bicep --output-format bicepparam

# Lint Bicep file
az bicep lint --file main.bicep

# Format Bicep file
az bicep format --file main.bicep

# Restore modules from registry
az bicep restore --file main.bicep
```
