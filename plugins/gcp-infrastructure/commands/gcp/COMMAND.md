# /gcp

Provision GCP infrastructure with Terraform, deploy to Cloud Run and GKE, configure workload identity, and secure with Cloud Armor.

## Usage

```
/gcp provision|run|identity|secure [options]
```

## Actions

### `provision`
Create and manage GCP resources with Terraform.

```bash
# Initialize Terraform with GCS backend
terraform init \
  -backend-config="bucket=myproject-tf-state" \
  -backend-config="prefix=prod/infrastructure"

# Plan with variable file
terraform plan \
  -var-file=environments/prod.tfvars \
  -out=tfplan

# Apply with auto-approve in CI
terraform apply tfplan

# GKE: Get credentials after cluster creation
gcloud container clusters get-credentials prod-cluster \
  --region us-central1 \
  --project myproject

# Create Artifact Registry repository
gcloud artifacts repositories create myapp \
  --repository-format=docker \
  --location=us-central1 \
  --description="MyApp container images"

# Configure Docker to push to Artifact Registry
gcloud auth configure-docker us-central1-docker.pkg.dev
```

### `run`
Deploy and manage Cloud Run services.

```bash
# Deploy to Cloud Run
gcloud run deploy myapp \
  --image us-central1-docker.pkg.dev/$PROJECT_ID/myapp:$IMAGE_TAG \
  --region us-central1 \
  --service-account myapp-prod@$PROJECT_ID.iam.gserviceaccount.com \
  --set-secrets=DB_PASSWORD=myapp-db-password:latest \
  --set-env-vars=NODE_ENV=production \
  --memory 512Mi \
  --cpu 1 \
  --min-instances 1 \
  --max-instances 100 \
  --vpc-connector projects/$PROJECT_ID/locations/us-central1/connectors/myapp-connector \
  --vpc-egress private-ranges-only

# View running revisions
gcloud run revisions list \
  --service myapp \
  --region us-central1

# Traffic split (canary: 10% to new revision)
gcloud run services update-traffic myapp \
  --region us-central1 \
  --to-revisions myapp-00010-abc=10,LATEST=90

# Roll back to specific revision
gcloud run services update-traffic myapp \
  --region us-central1 \
  --to-revisions myapp-00009-xyz=100

# View logs
gcloud run services logs read myapp \
  --region us-central1 \
  --limit 100

# Get Cloud Run URL
gcloud run services describe myapp \
  --region us-central1 \
  --format "value(status.url)"
```

### `identity`
Configure service accounts and Workload Identity.

```bash
# Create service account
gcloud iam service-accounts create myapp-prod \
  --display-name "MyApp Production" \
  --project $PROJECT_ID

# Grant predefined role to service account
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member "serviceAccount:myapp-prod@$PROJECT_ID.iam.gserviceaccount.com" \
  --role "roles/cloudsql.client" \
  --condition="title=prod-only,expression=resource.name.startsWith(\"projects/$PROJECT_ID/instances/prod\")"

# Workload Identity: bind K8s SA to GCP SA
gcloud iam service-accounts add-iam-policy-binding \
  myapp-prod@$PROJECT_ID.iam.gserviceaccount.com \
  --member "serviceAccount:$PROJECT_ID.svc.id.goog[myapp/myapp-sa]" \
  --role "roles/iam.workloadIdentityUser"

# List service accounts and their roles
gcloud iam service-accounts list --project $PROJECT_ID

# Download key (use only when Workload Identity not available)
# WARNING: avoid key files; prefer Workload Identity or OIDC
gcloud iam service-accounts keys create ~/sa-key.json \
  --iam-account myapp-prod@$PROJECT_ID.iam.gserviceaccount.com

# Verify effective permissions
gcloud auth application-default print-access-token | \
  jq -R '.' | xargs -I{} curl -H "Authorization: Bearer {}" \
  "https://iam.googleapis.com/v1/projects/$PROJECT_ID/serviceAccounts/myapp-prod@$PROJECT_ID.iam.gserviceaccount.com:getIamPolicy"
```

### `secure`
Configure Cloud Armor, VPC firewall, and security scanning.

```bash
# Create Cloud Armor security policy
gcloud compute security-policies create myapp-waf \
  --description "MyApp WAF and DDoS protection"

# Add OWASP SQLi rule
gcloud compute security-policies rules create 1000 \
  --security-policy myapp-waf \
  --expression "evaluatePreconfiguredExpr('sqli-v33-stable')" \
  --action deny-403 \
  --description "Block SQL injection"

# Add rate limiting (100 req/min per IP)
gcloud compute security-policies rules create 3000 \
  --security-policy myapp-waf \
  --src-ip-ranges '*' \
  --action rate-based-ban \
  --rate-limit-threshold-count 100 \
  --rate-limit-threshold-interval-sec 60 \
  --ban-duration-sec 600

# Attach to backend service
gcloud compute backend-services update myapp-backend \
  --security-policy myapp-waf \
  --global

# VPC firewall: deny all ingress by default, allow specific ports
gcloud compute firewall-rules create deny-all-ingress \
  --network main-vpc \
  --priority 65534 \
  --direction INGRESS \
  --action DENY \
  --rules all

gcloud compute firewall-rules create allow-https-from-lb \
  --network main-vpc \
  --priority 1000 \
  --direction INGRESS \
  --action ALLOW \
  --rules tcp:443 \
  --source-ranges 130.211.0.0/22,35.191.0.0/16 \  # GCP Load Balancer health check IPs
  --target-tags backend-server

# Enable Container Threat Detection
gcloud services enable containerthreatdetection.googleapis.com
```
