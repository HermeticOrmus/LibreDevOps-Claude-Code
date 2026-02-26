# Docker Orchestration Plugin

Multi-stage Dockerfiles, BuildKit cache optimization, docker-compose with health checks, container security, and image scanning.

## Components

- **Agent**: `docker-engineer` -- Multi-stage builds, layer caching, non-root users, distroless images, resource limits
- **Command**: `/docker` -- Builds multi-arch images, manages compose environments, scans with Trivy, optimizes layer sizes
- **Skill**: `docker-patterns` -- Language-specific Dockerfiles (Node/Python/Go/Java), compose templates, BuildKit cache, network isolation

## Quick Reference

```bash
# Build with BuildKit cache
DOCKER_BUILDKIT=1 docker build \
  --cache-from myregistry/myapp:buildcache \
  --build-arg BUILDKIT_INLINE_CACHE=1 \
  --tag myapp:$(git rev-parse --short HEAD) .

# Multi-arch build
docker buildx build --platform linux/amd64,linux/arm64 \
  --push --tag myregistry/myapp:v1.0.0 .

# Compose: start with rebuild
docker compose up --build --remove-orphans

# Scan for vulnerabilities
trivy image --severity HIGH,CRITICAL --exit-code 1 myapp:latest

# Lint Dockerfile
docker run --rm -i hadolint/hadolint < Dockerfile

# Analyze layer sizes
docker run --rm -it -v /var/run/docker.sock:/var/run/docker.sock \
  wagoodman/dive:latest myapp:latest
```

## Key Principles

**Layer order**: Copy dependency manifests (package.json, requirements.txt) and install before copying source code. Source code changes invalidate everything after the COPY; dependency install is expensive and should be cached.

**Multi-stage builds**: Separate build environment from runtime. Final image should contain only what's needed to run -- not compilers, test frameworks, or dev tools.

**Non-root user**: Always define a non-root user with `adduser`/`useradd` and switch to it before `CMD`/`ENTRYPOINT`. Running as root = privilege escalation if container breaks out.

**Health checks**: Define `HEALTHCHECK` in Dockerfile or in `compose.yml`. Without it, docker-compose and orchestrators can't know if your app is actually ready.

**Resource limits**: Always set `mem_limit` in production. Unbounded containers are how one service takes down an entire host.

## Related Plugins

- [container-registry](../container-registry/) -- ECR/GHCR push, Cosign signing, image lifecycle
- [kubernetes-operations](../kubernetes-operations/) -- Running containers in Kubernetes
- [github-actions](../github-actions/) -- CI pipeline for build, scan, push
- [infrastructure-security](../infrastructure-security/) -- Dockerfile security scanning with Checkov
