# /registry

Push images to ECR/GHCR, scan for vulnerabilities, sign with Cosign, and manage lifecycle policies.

## Usage

```
/registry push|scan|sign|clean [options]
```

## Actions

### `push`
Build and push images with multi-arch support.

```bash
# ECR: Authenticate and push
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  123456789.dkr.ecr.us-east-1.amazonaws.com

# Multi-arch build and push
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --tag 123456789.dkr.ecr.us-east-1.amazonaws.com/myapp:v1.2.3 \
  --tag 123456789.dkr.ecr.us-east-1.amazonaws.com/myapp:latest \
  --push \
  --cache-from type=registry,ref=123456789.dkr.ecr.us-east-1.amazonaws.com/myapp:buildcache \
  --cache-to type=registry,ref=123456789.dkr.ecr.us-east-1.amazonaws.com/myapp:buildcache,mode=max \
  .

# GHCR: Authenticate and push
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

docker build -t ghcr.io/myorg/myapp:v1.2.3 .
docker push ghcr.io/myorg/myapp:v1.2.3
```

### `scan`
Vulnerability scan with Trivy.

```bash
# Scan local image, fail on HIGH/CRITICAL
trivy image \
  --severity HIGH,CRITICAL \
  --exit-code 1 \
  --ignore-unfixed \
  myapp:latest

# Scan with full JSON output for reporting
trivy image \
  --format json \
  --output trivy-report.json \
  123456789.dkr.ecr.us-east-1.amazonaws.com/myapp:v1.2.3

# Scan Dockerfile (configuration issues)
trivy config \
  --severity HIGH,CRITICAL \
  --exit-code 1 \
  Dockerfile

# Scan running container in Kubernetes (via kubeconfig)
trivy k8s --report summary cluster

# ECR scan results (AWS Inspector)
aws ecr describe-image-scan-findings \
  --repository-name myapp \
  --image-id imageTag=v1.2.3 \
  --query 'imageScanFindings.findingSeverityCounts'

# List ECR images with HIGH vulnerabilities
aws inspector2 list-findings \
  --filter-criteria '{
    "ecrImageRepositoryName": [{"comparison":"EQUALS","value":"myapp"}],
    "severity": [{"comparison":"EQUALS","value":"HIGH"},{"comparison":"EQUALS","value":"CRITICAL"}]
  }' \
  --query 'findings[].{CVE:packageVulnerabilityDetails.vulnerabilityId,Severity:severity,Package:packageVulnerabilityDetails.vulnerablePackages[0].name}'
```

### `sign`
Sign images with Cosign for supply chain security.

```bash
# Install Cosign
COSIGN_VERSION=v2.2.2
curl -Lo cosign "https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/cosign-linux-amd64"
chmod +x cosign && sudo mv cosign /usr/local/bin/

# Keyless sign (requires OIDC token -- works in GitHub Actions automatically)
export COSIGN_EXPERIMENTAL=1
cosign sign --yes \
  123456789.dkr.ecr.us-east-1.amazonaws.com/myapp@sha256:DIGEST

# Verify signature
cosign verify \
  --certificate-identity-regexp "https://github.com/myorg/myrepo" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  123456789.dkr.ecr.us-east-1.amazonaws.com/myapp:v1.2.3

# Sign with explicit private key (for environments without OIDC)
cosign generate-key-pair                    # Creates cosign.key + cosign.pub
cosign sign --key cosign.key myapp:v1.2.3
cosign verify --key cosign.pub myapp:v1.2.3
```

### `clean`
Apply and manage ECR lifecycle policies, clean up stale images.

```bash
# Apply lifecycle policy to repository
aws ecr put-lifecycle-policy \
  --repository-name myapp \
  --lifecycle-policy-text file://ecr-lifecycle.json

# List all ECR images sorted by push date
aws ecr describe-images \
  --repository-name myapp \
  --query 'sort_by(imageDetails, &imagePushedAt)[*].{Digest:imageDigest,Tags:imageTags,Pushed:imagePushedAt,Size:imageSizeInBytes}' \
  --output table

# Find and delete untagged images manually
UNTAGGED=$(aws ecr list-images \
  --repository-name myapp \
  --filter tagStatus=UNTAGGED \
  --query 'imageIds[*]' \
  --output json)

if [ "$UNTAGGED" != "[]" ]; then
  aws ecr batch-delete-image \
    --repository-name myapp \
    --image-ids "$UNTAGGED"
fi

# Dry-run lifecycle policy (preview what would be deleted)
aws ecr get-lifecycle-policy-preview \
  --repository-name myapp \
  --query 'previewResults[*].{Tag:imageTagList,Action:action.type,Pushed:imagePushedAt}'
```

## ECR Lifecycle Policy Reference

```json
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Expire untagged after 7 days",
      "selection": {
        "tagStatus": "untagged",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 7
      },
      "action": { "type": "expire" }
    },
    {
      "rulePriority": 2,
      "description": "Keep last 10 release tags (v*)",
      "selection": {
        "tagStatus": "tagged",
        "tagPrefixList": ["v"],
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": { "type": "expire" }
    }
  ]
}
```
