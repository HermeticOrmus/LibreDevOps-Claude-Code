# GCP Infrastructure Plugin

GKE Autopilot, Cloud Run, Cloud SQL, Workload Identity, Terraform Google provider, and Cloud Armor patterns.

## Components

- **Agent**: `gcp-architect` -- Designs GKE clusters, Cloud Run services, Cloud SQL private IP, Workload Identity federation
- **Command**: `/gcp` -- Provisions with Terraform, deploys to Cloud Run, configures service accounts, secures with Cloud Armor
- **Skill**: `gcp-patterns` -- Full Workload Identity setup, Cloud Run + VPC connector, GitHub Actions OIDC, networking

## Quick Reference

```bash
# Deploy to Cloud Run
gcloud run deploy myapp \
  --image us-central1-docker.pkg.dev/$PROJECT_ID/myapp:$TAG \
  --region us-central1 \
  --service-account myapp@$PROJECT_ID.iam.gserviceaccount.com

# GKE credentials
gcloud container clusters get-credentials prod-cluster \
  --region us-central1

# Grant role to service account
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member "serviceAccount:myapp@$PROJECT_ID.iam.gserviceaccount.com" \
  --role "roles/cloudsql.client"

# Workload Identity binding
gcloud iam service-accounts add-iam-policy-binding \
  myapp@$PROJECT_ID.iam.gserviceaccount.com \
  --member "serviceAccount:$PROJECT_ID.svc.id.goog[namespace/k8s-sa]" \
  --role "roles/iam.workloadIdentityUser"

# View Cloud Run logs
gcloud run services logs read myapp --region us-central1
```

## Key Differences from AWS

| AWS | GCP Equivalent |
|-----|---------------|
| ECS/Fargate | Cloud Run (HTTP), GKE Autopilot |
| EC2 | Compute Engine |
| RDS | Cloud SQL |
| DynamoDB | Firestore, Bigtable |
| S3 | Cloud Storage (GCS) |
| ECR | Artifact Registry |
| IAM roles | Service Accounts + IAM roles |
| VPC Endpoints | Private Google Access, Private Service Connect |
| CloudWatch | Cloud Monitoring, Cloud Logging |
| Lambda | Cloud Functions |
| SQS/SNS | Pub/Sub |

## Workload Identity is Mandatory
Never use service account key files in GKE or Cloud Run. Workload Identity (GKE) and service account assignment (Cloud Run) provide identity without keys. For GitHub Actions, use GCP Workload Identity Federation with OIDC.

## Related Plugins

- [kubernetes-operations](../kubernetes-operations/) -- GKE workload management, Helm
- [terraform-patterns](../terraform-patterns/) -- Terraform patterns for GCP provider
- [container-registry](../container-registry/) -- Artifact Registry push and scanning
- [github-actions](../github-actions/) -- OIDC federation with GCP for CI/CD
