# Beginner Learning Path - DevOps Fundamentals

## Overview

This path introduces the core ideas behind DevOps: why it exists, what problems it solves, and how to build your first automated pipeline. You will work with Docker containers, write your first CI/CD pipeline, and understand the culture shift that makes DevOps more than just tooling. By the end, you will be able to containerize an application and deploy it automatically on every push.

## Prerequisites

- Comfortable with the command line (navigating directories, running commands)
- Basic Git knowledge (clone, commit, push, pull, branch)
- Familiarity with at least one programming language
- A GitHub account

## Modules

### Module 1: DevOps Culture and Fundamentals

#### Concepts

- DevOps is a culture, not a job title: breaking down the wall between development and operations
- The three ways: flow (left to right), feedback (right to left), continuous learning
- CALMS framework: Culture, Automation, Lean, Measurement, Sharing
- Version control as the single source of truth for everything: code, config, infrastructure
- The deployment pipeline: from commit to production, every step automated and auditable
- Environments: development, staging, production and why they exist
- Infrastructure as code: treating servers like cattle, not pets
- The feedback loop: monitoring informs development, development improves operations

#### Hands-On Exercise

Set up a basic development workflow:

1. Create a simple web application (a "Hello World" HTTP server in any language)
2. Initialize a Git repository with a clear branching strategy (main + feature branches)
3. Write a `Makefile` or `justfile` with targets for: `build`, `test`, `run`, `clean`
4. Add a `.editorconfig` and basic linting configuration
5. Create a `CONTRIBUTING.md` that documents your workflow

Push to GitHub. Verify that someone else could clone, build, and run your project by following your docs alone.

#### Key Takeaways

- DevOps starts with version control and automation, not with Kubernetes
- If the build is not reproducible, nothing downstream can be trusted
- Documentation is part of the pipeline, not a separate activity

### Module 2: Docker and Containerization

#### Concepts

- Containers vs virtual machines: isolation without the overhead
- Docker images: immutable snapshots of your application and its dependencies
- Dockerfiles: the recipe for building an image, layer by layer
- Docker Compose: orchestrating multi-container applications locally
- Image registries: Docker Hub, GitHub Container Registry, self-hosted options
- The build context: what gets sent to the Docker daemon and why `.dockerignore` matters
- Multi-stage builds: keeping production images small by separating build and runtime
- Container networking: how containers talk to each other and the outside world
- Volumes: persisting data beyond the container lifecycle
- Security basics: do not run as root, scan images for vulnerabilities, pin base image versions

#### Hands-On Exercise

Containerize the application from Module 1:

1. Write a `Dockerfile` using multi-stage build (build stage + production stage)
2. Create a `.dockerignore` file to exclude unnecessary files
3. Build the image and verify it runs: `docker build -t myapp . && docker run -p 8080:8080 myapp`
4. Write a `docker-compose.yml` that adds a database (PostgreSQL or Redis) alongside your app
5. Add a health check to your Dockerfile
6. Scan your image for vulnerabilities: `docker scout cves myapp` or `trivy image myapp`

Verify: your app should start with `docker compose up` and be accessible at `localhost:8080`. The database should persist data across restarts using a volume.

#### Key Takeaways

- Containers solve "it works on my machine" by making the machine part of the artifact
- Multi-stage builds are not optional: a 1GB image with build tools in production is a liability
- Docker Compose is for development; production orchestration needs different tools
- Container security starts at build time, not deployment time

### Module 3: Your First CI/CD Pipeline

#### Concepts

- Continuous Integration: every push triggers build and test automatically
- Continuous Delivery: every passing build is deployable; deployment is a business decision
- Continuous Deployment: every passing build deploys automatically (the full automation)
- GitHub Actions: workflows, jobs, steps, runners, and triggers
- Pipeline stages: lint, test, build, scan, deploy
- Artifacts: build outputs that persist between stages
- Secrets management: environment variables, GitHub Secrets, never in code
- Branch protection: require passing CI before merge
- Pipeline as code: the CI configuration is versioned alongside the application

#### Hands-On Exercise

Create a GitHub Actions CI/CD pipeline for your containerized application:

1. Create `.github/workflows/ci.yml` with these stages:
   - **Lint**: Run your language's linter
   - **Test**: Run unit tests
   - **Build**: Build the Docker image
   - **Scan**: Scan the image for vulnerabilities
2. Configure the pipeline to trigger on push and pull request to `main`
3. Add branch protection rules: require CI to pass before merging
4. Add a deployment step that pushes the image to GitHub Container Registry on merge to `main`
5. Store any credentials as GitHub Secrets (never hardcode them)

Test by creating a feature branch, making a change, opening a PR, and watching the pipeline run. Break a test intentionally and verify the pipeline catches it.

#### Key Takeaways

- CI is not optional: if you are not running tests on every push, bugs are queuing up silently
- Start simple: a pipeline that runs tests is infinitely better than no pipeline
- Secrets in code are a ticking time bomb; use secret management from day one
- The pipeline is the quality gate: if it passes, the code is shippable

## Assessment

You have completed the beginner path when you can:

1. Explain DevOps principles without referencing specific tools
2. Containerize any application with a multi-stage Dockerfile
3. Write a Docker Compose file for multi-service local development
4. Build a CI/CD pipeline that lints, tests, builds, and deploys automatically
5. Configure branch protection that enforces pipeline success before merge

## Next Steps

- Move to the **Intermediate Path**: Kubernetes, Terraform, and monitoring
- Practice by containerizing and adding CI/CD to an existing project
- Read "The Phoenix Project" by Gene Kim for the cultural foundations of DevOps
- Explore GitLab CI or Jenkins as alternative CI/CD platforms to broaden your perspective
