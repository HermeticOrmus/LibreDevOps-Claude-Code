# /docker

Build optimized images, manage docker-compose environments, scan for vulnerabilities, and debug containers.

## Usage

```
/docker build|compose|scan|optimize [options]
```

## Actions

### `build`
Build images with BuildKit, multi-arch, and proper caching.

```bash
# Enable BuildKit (set in CI or .bashrc)
export DOCKER_BUILDKIT=1

# Build with inline cache for CI reuse
docker build \
  --build-arg BUILDKIT_INLINE_CACHE=1 \
  --cache-from myregistry/myapp:buildcache \
  --tag myregistry/myapp:$(git rev-parse --short HEAD) \
  --tag myregistry/myapp:latest \
  .

# Multi-arch build with buildx (requires QEMU or cross-compilation)
docker run --privileged --rm tonistiigi/binfmt --install all
docker buildx create --use --name multiarch
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  --cache-from type=registry,ref=myregistry/myapp:buildcache \
  --cache-to type=registry,ref=myregistry/myapp:buildcache,mode=max \
  --tag myregistry/myapp:v1.2.3 \
  --push \
  .

# Build specific target stage
docker build --target deps --tag myapp:deps .
docker build --target builder --tag myapp:builder .
docker build --target runtime --tag myapp:latest .

# Build with secrets (not stored in image layers)
docker buildx build \
  --secret id=npmrc,src=$HOME/.npmrc \
  --tag myapp:latest .
```

### `compose`
Manage docker-compose for local development and staging.

```bash
# Start with rebuild (for code changes)
docker compose up --build --remove-orphans

# Start specific service with deps
docker compose up --build app

# Run in background
docker compose up -d

# View logs (all services or specific)
docker compose logs -f
docker compose logs -f --tail 50 app

# Exec into running service
docker compose exec app sh
docker compose exec db psql -U myapp -d myapp

# Run one-off commands
docker compose run --rm app npm run db:migrate
docker compose run --rm app python manage.py shell

# Stop and clean up (keep volumes)
docker compose down

# Nuclear cleanup (remove volumes and images)
docker compose down --volumes --rmi all

# Scale specific service
docker compose up --scale worker=3 -d

# Check service health
docker compose ps
docker inspect $(docker compose ps -q app) | jq '.[0].State.Health'
```

### `scan`
Vulnerability scanning and security checks.

```bash
# Trivy: scan image for vulnerabilities
trivy image \
  --severity HIGH,CRITICAL \
  --exit-code 1 \
  --ignore-unfixed \
  myapp:latest

# Trivy: scan Dockerfile for misconfigurations
trivy config \
  --severity MEDIUM,HIGH,CRITICAL \
  Dockerfile

# Trivy: scan docker-compose.yml
trivy config \
  --severity HIGH,CRITICAL \
  docker-compose.yml

# Dockerfile linting with hadolint
docker run --rm -i hadolint/hadolint < Dockerfile

# Check running containers for CVEs (Trivy k8s)
trivy image --severity CRITICAL $(docker ps --format '{{.Image}}' | sort -u)

# Docker Scout (official Docker security scanner)
docker scout cves myapp:latest
docker scout recommendations myapp:latest    # Suggest better base image
docker scout compare myapp:latest myapp:prev # Compare two versions
```

### `optimize`
Reduce image size and improve build performance.

```bash
# Analyze image layers and sizes
docker history myapp:latest
docker history --no-trunc myapp:latest | head -20

# Get image size
docker image ls myapp:latest --format "{{.Size}}"

# Dive: interactive layer explorer
docker run --rm -it \
  -v /var/run/docker.sock:/var/run/docker.sock \
  wagoodman/dive:latest myapp:latest

# docker-slim: auto-minimize image (experimental)
docker-slim build --target myapp:latest --tag myapp:slim

# Remove dangling images (untagged layers from old builds)
docker image prune -f

# Full cleanup (stopped containers, dangling images, unused networks)
docker system prune -f

# Aggressive cleanup including unused volumes
docker system prune --volumes -f

# Get disk usage breakdown
docker system df -v
```

## Dockerfile Quick Patterns

```bash
# Check effective user in container
docker run --rm myapp id

# Verify no secrets leaked into image environment
docker inspect myapp:latest | jq '.[0].Config.Env'

# Check open ports
docker inspect myapp:latest | jq '.[0].Config.ExposedPorts'

# Get CMD and ENTRYPOINT
docker inspect myapp:latest | jq '.[0].Config | {Cmd, Entrypoint}'

# Compare image sizes
for tag in v1.0.0 v1.1.0 v1.2.0; do
  echo -n "$tag: "
  docker image ls myapp:$tag --format "{{.Size}}"
done
```
