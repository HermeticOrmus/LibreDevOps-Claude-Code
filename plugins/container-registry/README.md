# Container Registry Plugin

ECR, GHCR, Harbor -- image building, vulnerability scanning (Trivy), Cosign signing, multi-arch builds, and lifecycle policies.

## Components

- **Agent**: `registry-manager` -- Image supply chain security, ECR lifecycle policies, multi-arch builds, signing strategy
- **Command**: `/registry` -- Push multi-arch images, scan with Trivy, sign with Cosign, clean up stale images
- **Skill**: `registry-patterns` -- ECR Terraform, Trivy in GitHub Actions, Cosign keyless, optimized Dockerfiles, SBOM

## When to Use

- Setting up ECR repositories with lifecycle policies and scanning
- Adding Trivy vulnerability scanning to CI pipelines (fail on HIGH/CRITICAL)
- Signing images with Cosign for supply chain security (keyless OIDC)
- Building multi-arch images (amd64 + arm64) with Docker Buildx
- Optimizing Dockerfile layer order to maximize build cache hits
- Generating and attaching SBOMs to container images

## Quick Reference

```bash
# ECR login
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin ACCOUNT.dkr.ecr.us-east-1.amazonaws.com

# Multi-arch build + push
docker buildx build --platform linux/amd64,linux/arm64 \
  --tag ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/myapp:v1.0.0 --push .

# Scan image
trivy image --severity HIGH,CRITICAL --exit-code 1 myapp:latest

# Sign with Cosign (keyless)
export COSIGN_EXPERIMENTAL=1
cosign sign --yes ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/myapp@sha256:DIGEST

# List ECR images
aws ecr describe-images --repository-name myapp \
  --query 'sort_by(imageDetails, &imagePushedAt)[*].{Tags:imageTags,Pushed:imagePushedAt}'
```

## Image Tag Strategy

| Context | Tag Format | Mutable? |
|---------|-----------|----------|
| Production | `v1.2.3` or `sha-abc1234` | No (IMMUTABLE on ECR) |
| Staging | `main-latest` | Yes |
| PR Preview | `pr-123-latest` | Yes |
| Build cache | `buildcache` | Yes |
| Never use | `latest` for production | -- |

## Related Plugins

- [docker-orchestration](../docker-orchestration/) -- Dockerfile best practices, multi-stage builds
- [github-actions](../github-actions/) -- CI pipeline for build-scan-sign workflow
- [infrastructure-security](../infrastructure-security/) -- Checkov container scanning
- [kubernetes-operations](../kubernetes-operations/) -- Image pull secrets, ECR auth
