# Learning Path: DevOps Fundamentals

> For engineers beginning their DevOps journey. No prior infrastructure experience required beyond basic terminal usage.

---

## What You Will Learn

By the end of this path, you will understand:

- What DevOps is and why it exists (the cultural and technical problem it solves)
- How to containerize an application with Docker
- How to build your first CI/CD pipeline
- The basics of infrastructure as code
- How monitoring prevents 3am pages
- The vocabulary and mental models used by infrastructure teams

---

## Prerequisites

- Comfortable with a terminal (cd, ls, cp, mv, cat, grep)
- Basic understanding of how web applications work (client sends request, server responds)
- A code editor you can navigate
- Docker Desktop or Docker Engine installed
- A GitHub account

---

## Phase 1: Understanding the Landscape

### 1.1 What Problem Does DevOps Solve?

Before DevOps, two teams existed in tension:

- **Development** wanted to ship features fast
- **Operations** wanted to keep systems stable

These goals conflicted. Developers threw code "over the wall" to ops. Ops blamed developers when things broke. Releases happened quarterly, took entire weekends, and frequently failed.

**DevOps dissolves this wall.** The same team (or tightly collaborating teams) builds, deploys, and operates the software. The result: faster releases, fewer failures, faster recovery.

The three pillars:
1. **Culture** -- Shared responsibility for the full lifecycle
2. **Automation** -- Eliminate manual, error-prone steps
3. **Measurement** -- You cannot improve what you do not measure

### 1.2 The DevOps Toolchain

Every tool in DevOps maps to a phase of the software lifecycle:

| Phase | What Happens | Common Tools |
|-------|-------------|--------------|
| **Plan** | Define work, track progress | Jira, Linear, GitHub Issues |
| **Code** | Write application and infrastructure code | Git, VS Code, Claude Code |
| **Build** | Compile, package, create artifacts | Docker, Maven, npm, Go build |
| **Test** | Validate correctness and security | pytest, Jest, Trivy, tfsec |
| **Release** | Version and prepare for deployment | Semantic versioning, Git tags |
| **Deploy** | Put code into an environment | Terraform, Helm, kubectl, CI/CD |
| **Operate** | Keep systems running | Kubernetes, systemd, auto-scaling |
| **Monitor** | Observe health and performance | Prometheus, Grafana, ELK, PagerDuty |

You do not need all of these on day one. Start with Code, Build, Deploy, Monitor.

### 1.3 Key Vocabulary

Learn these terms. They appear in every DevOps conversation:

- **Artifact** -- A built, versioned package of your application (Docker image, JAR file, binary)
- **CI (Continuous Integration)** -- Automatically building and testing every code change
- **CD (Continuous Delivery/Deployment)** -- Automatically deploying tested code to environments
- **IaC (Infrastructure as Code)** -- Defining servers, networks, and databases in version-controlled files instead of clicking through consoles
- **Container** -- A lightweight, isolated package that includes your application and all its dependencies
- **Orchestration** -- Managing multiple containers across multiple machines (Kubernetes)
- **Pipeline** -- An automated sequence of build, test, and deploy steps
- **Environment** -- A distinct deployment target (dev, staging, production)
- **Idempotent** -- An operation that produces the same result whether run once or many times
- **State** -- The current configuration of your infrastructure, tracked by IaC tools
- **Secret** -- Any sensitive value (API key, password, token) that must not be in code
- **Health check** -- An automated test that verifies a service is running correctly
- **SLA/SLO/SLI** -- Service Level Agreement/Objective/Indicator. Promises about reliability.
- **Rollback** -- Reverting a deployment to a previous known-good state

---

## Phase 2: Containers with Docker

### 2.1 Why Containers?

The classic problem: "It works on my machine."

Containers solve this by packaging your application with its exact dependencies, configuration, and runtime. A container runs identically on your laptop, in CI, and in production.

**Mental model:** A container is like a shipping container. Standard shape, predictable interface, contents vary. The ship (host OS) does not care what is inside -- it just runs them.

### 2.2 Your First Dockerfile

```dockerfile
# Every Dockerfile starts with a base image
# This is the foundation your application builds on
FROM node:20-alpine

# Set the working directory inside the container
WORKDIR /app

# Copy dependency definitions first (for caching)
# Docker caches layers. If package.json hasn't changed,
# it skips the npm install step on rebuild.
COPY package.json package-lock.json ./

# Install dependencies
RUN npm ci --production

# Copy application code
COPY src/ ./src/

# Expose the port your app listens on
# This is documentation -- it doesn't actually open the port
EXPOSE 3000

# Health check -- Docker will monitor this
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

# The command that runs when the container starts
CMD ["node", "src/server.js"]
```

### 2.3 Building and Running

```bash
# Build the image (the -t flag tags it with a name)
docker build -t my-app:v1 .

# Run the container
# -d: detached (background)
# -p: port mapping (host:container)
# --name: human-readable container name
docker run -d -p 3000:3000 --name my-app my-app:v1

# Check it's running
docker ps

# View logs
docker logs my-app

# Stop and remove
docker stop my-app && docker rm my-app
```

### 2.4 Docker Compose for Local Development

When your application needs multiple services (app + database + cache), use Docker Compose:

```yaml
# docker-compose.yml
version: "3.8"

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgres://user:pass@db:5432/myapp
      - REDIS_URL=redis://cache:6379
    depends_on:
      db:
        condition: service_healthy
      cache:
        condition: service_started

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: myapp
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d myapp"]
      interval: 5s
      timeout: 3s
      retries: 5

  cache:
    image: redis:7-alpine

volumes:
  pgdata:
```

```bash
# Start all services
docker compose up -d

# View logs for all services
docker compose logs -f

# Stop and remove everything
docker compose down

# Stop and remove everything INCLUDING data volumes
docker compose down -v
```

### 2.5 Exercises

1. **Containerize a simple web app** -- Take any "hello world" web app and create a Dockerfile for it
2. **Add a database** -- Create a docker-compose.yml that runs your app with PostgreSQL
3. **Explore layers** -- Run `docker history my-app:v1` and understand what each layer does
4. **Break it** -- Remove the health check, introduce a bug, and observe how Docker reports the container status

---

## Phase 3: Your First CI/CD Pipeline

### 3.1 What CI/CD Actually Does

A CI/CD pipeline automates the boring, error-prone parts of shipping software:

1. **Trigger**: Someone pushes code to a branch
2. **Build**: The code is compiled/packaged automatically
3. **Test**: Automated tests run. If they fail, the pipeline stops.
4. **Security scan**: Dependencies and code are checked for vulnerabilities
5. **Deploy**: If all checks pass, deploy to an environment

Without CI/CD, each of these steps is manual. Manual steps get skipped when people are in a hurry. Skipped steps cause production incidents.

### 3.2 GitHub Actions -- The Simplest Start

GitHub Actions runs directly in your GitHub repository. No external services needed.

```yaml
# .github/workflows/ci.yml
name: CI Pipeline

# When does this pipeline run?
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build-and-test:
    # What machine does this run on?
    runs-on: ubuntu-latest

    steps:
      # Step 1: Get the code
      - name: Checkout code
        uses: actions/checkout@v4

      # Step 2: Set up the runtime
      - name: Set up Node.js
        uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"

      # Step 3: Install dependencies
      - name: Install dependencies
        run: npm ci

      # Step 4: Run linter
      - name: Lint
        run: npm run lint

      # Step 5: Run tests
      - name: Test
        run: npm test

      # Step 6: Build the application
      - name: Build
        run: npm run build

      # Step 7: Build Docker image (verify it builds)
      - name: Build Docker image
        run: docker build -t my-app:${{ github.sha }} .
```

### 3.3 Understanding the Pipeline

Each piece of the YAML above serves a purpose:

- `on:` -- Defines triggers. This runs on pushes to main and on PRs targeting main.
- `runs-on:` -- The operating system for the CI runner. `ubuntu-latest` is the most common.
- `steps:` -- Sequential actions. If any step fails, the pipeline stops.
- `uses:` -- References a reusable action (someone else's automation you can use)
- `run:` -- Executes a shell command

### 3.4 Adding Deployment

Once CI passes, deploy to a staging environment:

```yaml
  deploy-staging:
    needs: build-and-test          # Only runs after build-and-test succeeds
    if: github.ref == 'refs/heads/main'  # Only on main branch
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Build and push Docker image
        run: |
          docker build -t my-registry/my-app:${{ github.sha }} .
          docker push my-registry/my-app:${{ github.sha }}

      - name: Deploy to staging
        run: |
          # This is where you'd use kubectl, terraform, or a cloud CLI
          echo "Deploying version ${{ github.sha }} to staging"
```

### 3.5 Exercises

1. **Create your first workflow** -- Add the CI pipeline above to a GitHub repository and push code to trigger it
2. **Make it fail** -- Introduce a linting error or failing test. Observe how the pipeline blocks the PR.
3. **Add a step** -- Add a security scanning step using `npm audit` or `trivy`
4. **Branch protection** -- Enable branch protection on `main` to require CI to pass before merging

---

## Phase 4: Infrastructure as Code Basics

### 4.1 Why Code Instead of Clicking?

Clicking through a cloud console to create resources is:
- **Not repeatable** -- Can you create the exact same setup in a new account?
- **Not auditable** -- Who changed what and when?
- **Not reviewable** -- No one can review a click before it happens
- **Not recoverable** -- If someone deletes a resource, can you recreate it?

Infrastructure as Code solves all four problems. Your infrastructure is defined in files, stored in git, reviewed in PRs, and applied automatically.

### 4.2 Terraform -- The Most Common IaC Tool

Terraform uses a declarative language (HCL) to describe what your infrastructure should look like. Terraform figures out how to make reality match your description.

```hcl
# main.tf -- A simple example

# Tell Terraform which cloud provider to use
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the provider
provider "aws" {
  region = "us-east-1"
}

# Define a resource
resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-unique-bucket-name-12345"

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
    Project     = "learning"
  }
}
```

### 4.3 The Terraform Workflow

```bash
# 1. Initialize -- Download provider plugins
terraform init

# 2. Plan -- Preview what Terraform will do
terraform plan
# This shows you EXACTLY what will be created, modified, or destroyed
# ALWAYS review the plan before applying

# 3. Apply -- Make it happen
terraform apply
# Terraform asks for confirmation before proceeding

# 4. Destroy -- Clean up (important for learning to avoid costs)
terraform destroy
```

### 4.4 The Critical Concept: State

Terraform keeps a **state file** that maps your code to real resources. This is how Terraform knows what exists and what needs to change.

**State is critical.** If you lose the state file, Terraform does not know about your existing resources. It will try to create duplicates.

For learning, local state is fine. For real projects, always use a remote backend (S3, GCS, or Terraform Cloud).

### 4.5 Exercises

1. **Install Terraform** -- Download from terraform.io, run `terraform version`
2. **Read a plan** -- Write the S3 bucket example above, run `terraform plan`, and read every line of output
3. **Apply and destroy** -- Create the bucket, verify it exists in the AWS console, then destroy it
4. **Modify** -- Change the tags, run `terraform plan`, and observe how Terraform shows the diff

---

## Phase 5: Monitoring Fundamentals

### 5.1 Why Monitor?

Monitoring answers three questions:
1. **Is it working?** (health checks, uptime)
2. **Is it fast enough?** (latency, throughput)
3. **Is it about to break?** (resource utilization, error rates)

Without monitoring, you learn about problems from your users. That is not a good feedback loop.

### 5.2 The Four Golden Signals

Google's Site Reliability Engineering book defines four signals every service should monitor:

| Signal | What It Measures | Example Metric |
|--------|-----------------|----------------|
| **Latency** | Time to serve a request | p95 response time |
| **Traffic** | Demand on the system | Requests per second |
| **Errors** | Rate of failed requests | 5xx responses per second |
| **Saturation** | How full the system is | CPU usage, memory usage, queue depth |

### 5.3 Health Checks

The simplest form of monitoring: periodically ask "are you alive?"

```javascript
// A basic health check endpoint
app.get("/health", (req, res) => {
  // Check that critical dependencies are reachable
  const dbHealthy = await checkDatabaseConnection();
  const cacheHealthy = await checkRedisConnection();

  if (dbHealthy && cacheHealthy) {
    res.status(200).json({ status: "healthy" });
  } else {
    res.status(503).json({
      status: "unhealthy",
      db: dbHealthy,
      cache: cacheHealthy,
    });
  }
});
```

### 5.4 Structured Logging

Logs are only useful if they are searchable. Use structured (JSON) logging:

```json
{
  "timestamp": "2026-02-24T10:30:00Z",
  "level": "error",
  "message": "Database connection failed",
  "service": "api",
  "environment": "production",
  "error_code": "ECONNREFUSED",
  "retry_count": 3,
  "trace_id": "abc123"
}
```

This is searchable. `level:error AND service:api` finds all API errors. Unstructured logs ("Error: something broke at line 42") are not.

### 5.5 Exercises

1. **Add a health endpoint** -- Add `/health` to any web application
2. **Docker health check** -- Add a HEALTHCHECK instruction to your Dockerfile that hits the endpoint
3. **Structured logging** -- Replace `console.log` with a structured logger (pino, winston, or your language's equivalent)
4. **Dashboard thinking** -- List the 5 most important metrics for your application. What would you put on a dashboard?

---

## Phase 6: Putting It Together

### 6.1 The Complete Beginner Stack

You now have the pieces to build a complete workflow:

1. **Code** in a Git repository
2. **Containerize** with Docker
3. **Test and build** with CI/CD (GitHub Actions)
4. **Define infrastructure** with Terraform (or start with Docker Compose)
5. **Monitor** with health checks and structured logs

### 6.2 A Realistic First Project

Build a containerized web application with:

- A Dockerfile with health check
- A docker-compose.yml with app + database
- A GitHub Actions CI pipeline that builds, tests, and builds the Docker image
- A health endpoint that checks database connectivity
- Structured JSON logging

This is a real, deployable stack. It is not production-grade yet (you need proper secrets management, monitoring, backup, and more), but it is a solid foundation.

### 6.3 Pre-Deployment Checklist

Before deploying anything, even to a development environment:

- [ ] No hardcoded secrets in code, Dockerfiles, or CI configs
- [ ] Health check endpoint exists and checks critical dependencies
- [ ] Docker image builds successfully in CI
- [ ] All tests pass
- [ ] Logs are structured (JSON) and include service name and environment
- [ ] `.gitignore` excludes `.env`, `*.key`, `*.pem`, and cloud credentials
- [ ] README documents how to build, run, and test locally

---

## What Comes Next

Once you are comfortable with these fundamentals, the [Intermediate Path](intermediate.md) covers:

- Kubernetes for container orchestration
- Terraform modules for reusable infrastructure
- Monitoring stacks (Prometheus + Grafana)
- Multi-environment deployments (dev/staging/production)
- Secrets management beyond environment variables

---

## Recommended Resources

- **Docker documentation**: https://docs.docker.com/get-started/
- **GitHub Actions documentation**: https://docs.github.com/en/actions
- **Terraform tutorials**: https://developer.hashicorp.com/terraform/tutorials
- **The Phoenix Project** (book): Understanding the DevOps cultural shift
- **Google SRE Book** (free online): https://sre.google/sre-book/table-of-contents/

---

## Plugin Recommendations for Beginners

Start with these plugins from the LibreDevOps collection:

| Plugin | Why Start Here |
|--------|---------------|
| [docker-orchestration](../plugins/docker-orchestration/) | Foundation for all container work |
| [github-actions](../plugins/github-actions/) | Simplest CI/CD platform to learn |
| [terraform-patterns](../plugins/terraform-patterns/) | Industry standard IaC tool |
| [monitoring-observability](../plugins/monitoring-observability/) | Cannot operate what you cannot observe |
| [secret-management](../plugins/secret-management/) | Security habits start on day one |
