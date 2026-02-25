# Beginner: Infrastructure Foundations with Claude Code

> Infrastructure is the foundation that everything else runs on. When it fails, everything above it fails too. The goal is not to build complex systems -- it is to build reliable ones.

---

## Table of Contents

1. [The Infrastructure Mindset](#the-infrastructure-mindset)
2. [Docker: Your First Container](#docker-your-first-container)
3. [Terraform: Your First Infrastructure](#terraform-your-first-infrastructure)
4. [CI/CD: Your First Pipeline](#cicd-your-first-pipeline)
5. [Three Rules of Infrastructure Prompting](#three-rules-of-infrastructure-prompting)
6. [Common Mistakes Claude Makes with Infrastructure](#common-mistakes-claude-makes-with-infrastructure)
7. [Quick Reference: Production Patterns](#quick-reference-production-patterns)
8. [Practice Exercises](#practice-exercises)
9. [Infrastructure Vocabulary](#infrastructure-vocabulary)

---

## The Infrastructure Mindset

Infrastructure engineering is about managing the gap between "it works on my machine" and "it works reliably for thousands of users in production." This gap is where the following concerns live:

**Reproducibility**: Can you rebuild the entire system from scratch if it disappears? If the answer depends on someone's memory or a series of manual clicks in a web console, you do not have infrastructure -- you have a house of cards.

**Idempotency**: Can you run the same operation twice without breaking anything? Terraform apply, Ansible playbooks, Docker builds -- they should produce the same result whether run once or a hundred times.

**Observability**: When something goes wrong at 3 AM, can you figure out what happened without guessing? Logs, metrics, traces, and alerts are not optional -- they are the difference between a 5-minute fix and a 5-hour outage.

**Applied to Claude Code**: When you ask Claude to generate infrastructure, it optimizes for "working" -- a Docker container that starts, a Terraform file that validates, a pipeline that runs. But "working" and "production-ready" are different properties. Production-ready means state is managed, secrets are handled, failures are anticipated, and monitoring exists. You must explicitly request these.

### The Tutorial vs. Production Gap

| Concern | Tutorial Version | Production Version |
|---------|-----------------|-------------------|
| State | Local `.tfstate` file | Remote backend with locking and encryption |
| Secrets | Hardcoded in config | Secret manager with rotation |
| Networking | Default VPC, everything public | Custom VPC, private subnets, security groups |
| Containers | `FROM node:latest`, root user | Pinned version, non-root, health checks |
| CI/CD | Single branch, no gates | Multi-stage with tests, scans, approvals |
| Monitoring | `console.log` | Structured logging, metrics, alerts, dashboards |
| Backup | "We should set up backups" | Automated daily, tested monthly, cross-region |
| DNS | Hard-coded IP addresses | Managed DNS with health checks and failover |

---

## Docker: Your First Container

Docker packages an application and all its dependencies into a single artifact that runs identically everywhere. No more "it works on my machine."

### The Naive Dockerfile

Claude generates this when you say "Dockerize my Node app":

```dockerfile
FROM node:latest
WORKDIR /app
COPY . .
RUN npm install
EXPOSE 3000
CMD ["node", "index.js"]
```

This works. It also has six problems.

### The Production Dockerfile

```dockerfile
# Stage 1: Build
FROM node:22.12-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --production=false
COPY . .
RUN npm run build

# Stage 2: Production
FROM node:22.12-alpine AS production
RUN addgroup -g 1001 appgroup && adduser -u 1001 -G appgroup -D appuser

WORKDIR /app
COPY --from=builder --chown=appuser:appgroup /app/dist ./dist
COPY --from=builder --chown=appuser:appgroup /app/node_modules ./node_modules
COPY --from=builder --chown=appuser:appgroup /app/package.json ./

USER appuser
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

CMD ["node", "dist/index.js"]
```

**Why each change matters:**
1. **Pinned version** (`22.12-alpine` not `latest`): Reproducible builds. `latest` changes without warning.
2. **Alpine base**: ~50MB instead of ~1GB. Smaller attack surface.
3. **Multi-stage build**: Build tools do not ship to production. Final image contains only runtime code.
4. **Non-root user**: If the container is compromised, the attacker cannot modify the host.
5. **HEALTHCHECK**: Orchestrators (Docker Compose, ECS, Kubernetes) know when the container is actually ready.
6. **`npm ci`**: Installs exact versions from lockfile. `npm install` can produce different results.

---

## Terraform: Your First Infrastructure

Terraform lets you describe infrastructure in code and create it with a single command. More importantly, it lets you change, version, and destroy infrastructure the same way.

### The Naive Terraform

Claude generates this for "create an EC2 instance":

```hcl
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "web" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
}
```

This creates an instance. It also stores state locally (one laptop failure away from disaster), uses the default VPC (probably misconfigured), has no security group (wide open), and hardcodes the AMI (will become outdated).

### The Production Terraform

```hcl
# backend.tf -- remote state with locking
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.82.0"
    }
  }

  backend "s3" {
    bucket         = "myapp-terraform-state"
    key            = "dev/ec2/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "myapp-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# variables.tf -- parameterized, not hardcoded
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

# data.tf -- dynamic AMI lookup
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# main.tf -- the actual resource with security
resource "aws_security_group" "web" {
  name_prefix = "${var.project_name}-${var.environment}-web-"
  description = "Security group for web server"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-web-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [aws_security_group.web.id]
  iam_instance_profile   = aws_iam_instance_profile.web.name

  monitoring = true

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  metadata_options {
    http_tokens                 = "required"  # IMDSv2
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-web"
  }
}

# outputs.tf -- expose what consumers need
output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.web.id
}

output "private_ip" {
  description = "Private IP address"
  value       = aws_instance.web.private_ip
}
```

**Why each change matters:**
1. **Remote state backend**: State is shared, locked, encrypted, and versioned. Losing your laptop does not lose your infrastructure.
2. **Provider version pinning**: Prevents surprise breaking changes from provider updates.
3. **Variables with validation**: Parameterized for reuse across environments. Validation prevents typos.
4. **Dynamic AMI lookup**: Always uses the latest Amazon Linux without hardcoding.
5. **Security group**: Explicit rules instead of default VPC wide-open access.
6. **Private subnet**: Not directly internet-accessible.
7. **Encrypted volumes**: Data at rest encryption.
8. **IMDSv2 required**: Prevents SSRF attacks from stealing instance credentials.
9. **Tags**: Every resource is traceable to project, environment, and management tool.

---

## CI/CD: Your First Pipeline

CI/CD automates the path from code commit to running in production. Without it, every deployment is a manual, error-prone event.

### The Naive Pipeline

```yaml
# Claude generates this for "set up CI/CD"
name: Deploy
on: push
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm install
      - run: npm test
      - run: npm run deploy
```

This runs on every push to every branch, has no environment separation, no security scanning, no approval process, and stores the deploy command (with its required credentials) somewhere unspecified.

### The Production Pipeline

```yaml
name: CI/CD Pipeline
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

permissions:
  contents: read
  id-token: write    # For OIDC to cloud provider

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version-file: '.nvmrc'
          cache: 'npm'

      - run: npm ci
      - run: npm run lint
      - run: npm run type-check
      - run: npm test -- --coverage

      - name: Secret scan
        uses: trufflesecurity/trufflehog@main
        with:
          extra_args: --only-verified

  build:
    needs: validate
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci
      - run: npm run build

      - name: Build container image
        run: docker build -t app:${{ github.sha }} .

      - name: Scan container image
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: app:${{ github.sha }}
          severity: CRITICAL,HIGH
          exit-code: 1

  deploy-staging:
    needs: build
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/github-deploy-staging
          aws-region: us-east-1

      - name: Deploy to staging
        run: ./scripts/deploy.sh staging ${{ github.sha }}

      - name: Run health checks
        run: ./scripts/health-check.sh https://staging.example.com

  deploy-production:
    needs: deploy-staging
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://example.com
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/github-deploy-production
          aws-region: us-east-1

      - name: Deploy to production
        run: ./scripts/deploy.sh production ${{ github.sha }}

      - name: Run health checks
        run: ./scripts/health-check.sh https://example.com

      - name: Notify deployment
        if: success()
        run: echo "Deployed ${{ github.sha }} to production"
```

**Why each change matters:**
1. **Branch protection**: Only runs on `main` and PRs to `main`, not every push.
2. **Separate jobs**: Validate, build, deploy-staging, deploy-production. Each can fail independently.
3. **OIDC authentication**: No long-lived AWS credentials stored in GitHub. Short-lived tokens via OIDC federation.
4. **Environment gates**: `environment: production` requires manual approval (configured in GitHub settings).
5. **Secret scanning**: Catches accidentally committed credentials before deployment.
6. **Container scanning**: Finds vulnerabilities in the Docker image before it reaches any environment.
7. **Health checks**: Verifies the deployment actually works, not just that it ran without errors.
8. **Sequential deployment**: Staging must succeed before production is even attempted.

---

## Three Rules of Infrastructure Prompting

### Rule 1: Specify the Environment

Infrastructure is always environment-specific. A config that works for development will break in production.

**Vague** (produces tutorial configs):
```
"Create a Terraform config for an RDS database"
```

**Specific** (produces production configs):
```
"Create a Terraform config for an RDS PostgreSQL 16 instance for
a production SaaS application. Requirements: Multi-AZ deployment,
encrypted storage with AWS KMS, automated backups with 30-day
retention, private subnet only (no public access), security group
allowing connections only from the application subnet CIDR, IAM
authentication enabled, performance insights enabled, minor version
auto-upgrade enabled. Use variables for instance class, storage
size, and database name. Include outputs for endpoint and port."
```

### Rule 2: Require State and Secret Management

Claude will generate infrastructure without state backends or secret handling unless you ask.

```
"Generate Terraform for an ECS Fargate service. Include:
- S3 backend with DynamoDB state locking
- Secrets from AWS Secrets Manager (not environment variables)
- Variables for environment (dev/staging/prod) with different
  instance sizes per environment
- Remote state data source for VPC and subnet IDs from the
  networking state file"
```

### Rule 3: Demand Monitoring Alongside Infrastructure

Infrastructure without monitoring is infrastructure you will discover is broken when customers tell you.

```
"For every resource you create, also create:
- CloudWatch alarms for key metrics (CPU, memory, error rate)
- A CloudWatch dashboard showing resource health
- SNS topic for alert notifications
- Log group with 90-day retention
Include alarm thresholds appropriate for production."
```

---

## Common Mistakes Claude Makes with Infrastructure

### Missing State Backend

Claude generates Terraform with local state by default. This means state lives on one machine and cannot be shared, locked, or recovered.

```hcl
# Claude generates this (local state, no locking)
terraform {
  required_providers {
    aws = { source = "hashicorp/aws" }
  }
}

# What you need (remote state with locking)
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
```

### Hardcoded Secrets in Infrastructure

```hcl
# Claude generates this
resource "aws_db_instance" "main" {
  username = "admin"
  password = "supersecretpassword123"
}

# What you need
resource "aws_db_instance" "main" {
  username                    = var.db_username
  manage_master_user_password = true  # AWS manages and rotates the password
}
```

### Default VPC and Public Subnets

Claude puts everything in the default VPC with public IPs unless told otherwise. Databases, caches, and application servers should be in private subnets.

### Missing Resource Limits

```yaml
# Claude generates this (no limits)
services:
  app:
    image: myapp:latest

# What you need (resource limits prevent one container from killing the host)
services:
  app:
    image: myapp:1.2.3
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 128M
```

### No Health Checks

Claude rarely adds health checks unless asked. Without them, orchestrators cannot detect unhealthy instances.

### Unpinned Versions

`FROM node:latest`, `hashicorp/aws ~> 5.0`, `actions/checkout@main` -- all of these can change without warning and break your builds.

---

## Quick Reference: Production Patterns

### Docker Compose (Development)

```yaml
services:
  app:
    build:
      context: .
      target: production
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgresql://user:pass@db:5432/myapp
      - NODE_ENV=production
    depends_on:
      db:
        condition: service_healthy
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
    healthcheck:
      test: ["CMD", "wget", "--spider", "http://localhost:3000/health"]
      interval: 30s
      timeout: 5s
      retries: 3

  db:
    image: postgres:16.4-alpine
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: myapp
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d myapp"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  pgdata:
```

### Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  labels:
    app: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1001
        fsGroup: 1001
      containers:
        - name: myapp
          image: myapp:1.2.3
          ports:
            - containerPort: 3000
          resources:
            requests:
              cpu: 250m
              memory: 128Mi
            limits:
              cpu: "1"
              memory: 512Mi
          readinessProbe:
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /health
              port: 3000
            initialDelaySeconds: 15
            periodSeconds: 20
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: myapp-secrets
                  key: database-url
```

---

## Practice Exercises

### Exercise 1: Fix the Dockerfile

This Dockerfile has multiple production issues. Identify and fix them.

```dockerfile
FROM node
WORKDIR /app
COPY . .
RUN npm install
EXPOSE 3000 22
CMD npm start
```

**Issues to find**: Unpinned base image, no multi-stage build, `npm install` instead of `npm ci`, running as root, exposing SSH port, no health check, copies everything including `node_modules` and `.git`.

### Exercise 2: Fix the Terraform

```hcl
provider "aws" {}

resource "aws_s3_bucket" "data" {
  bucket = "my-data-bucket"
}

resource "aws_db_instance" "main" {
  engine         = "postgres"
  instance_class = "db.t3.micro"
  username       = "admin"
  password       = "admin123"
}
```

**Issues to find**: No state backend, no provider version, no region, S3 bucket without encryption or versioning, public by default, hardcoded database credentials, no backup configuration, no tags, no security group.

### Exercise 3: Write a Production Pipeline

Using Claude Code, write a GitHub Actions pipeline that:
- Runs on PRs and pushes to main
- Validates Terraform configuration (`fmt`, `validate`, `plan`)
- Runs `tfsec` for security scanning
- Requires manual approval for production apply
- Uses OIDC for AWS authentication (no long-lived secrets)
- Includes status comments on PRs

Use the prompt template in `prompts/deploy-docker-app.md` as your starting point.

---

## Pre-Deployment Checklist

See `checklist.md` for the full infrastructure checklist.

Quick version:

- [ ] State backend configured with locking and encryption?
- [ ] All secrets from a secret manager (not hardcoded)?
- [ ] Resources in private subnets where appropriate?
- [ ] Health checks on all services?
- [ ] Resource limits set (CPU, memory)?
- [ ] Versions pinned (images, providers, actions)?
- [ ] Monitoring and alerting configured?
- [ ] Backup and recovery tested?
- [ ] Rollback procedure documented?
- [ ] Costs estimated?

---

## Infrastructure Vocabulary

See `infra-vocabulary.md` for a comprehensive glossary. Quick essentials:

| Term | Meaning |
|------|---------|
| **IaC** | Infrastructure as Code -- managing infrastructure through version-controlled config files |
| **State** | The record of what resources exist and their current configuration (e.g., Terraform state) |
| **Idempotent** | Can be run multiple times with the same result -- essential for infrastructure operations |
| **Drift** | When actual infrastructure differs from what is defined in code |
| **Blue-Green** | Deployment strategy using two identical environments for zero-downtime releases |
| **Health Check** | An endpoint or command that reports whether a service is ready to accept traffic |

---

## Next Steps

Once you are comfortable with these fundamentals:

1. Complete all three practice exercises
2. Use the `checklist.md` for your next five infrastructure tasks
3. Read the `prompts/deploy-docker-app.md` to see what a thorough infrastructure prompt looks like
4. Move to `../intermediate/` for multi-environment Terraform, Kubernetes patterns, and monitoring stacks

---

*Part of [LibreDevOps-Claude-Code](https://github.com/HermeticOrmus/LibreDevOps-Claude-Code) -- MIT License*
