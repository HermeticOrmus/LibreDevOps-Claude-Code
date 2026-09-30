# /gitlab-ci

Design GitLab CI pipelines, add security scanning, configure environments, and debug failing jobs.

## Usage

```
/gitlab-ci design|template|secure|deploy [options]
```

## Actions

### `design`
Generate a complete .gitlab-ci.yml with DAG and rules.

```yaml
# Minimal but complete pipeline
stages: [build, test, deploy]

variables:
  DOCKER_BUILDKIT: "1"
  IMAGE: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA

# Shared build template
.docker:
  image: docker:24
  services: [docker:24-dind]
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY

# Job definitions
build:
  extends: .docker
  stage: build
  script:
    - docker build --cache-from $CI_REGISTRY_IMAGE:cache
        --tag $IMAGE --tag $CI_REGISTRY_IMAGE:cache .
    - docker push $IMAGE
    - docker push $CI_REGISTRY_IMAGE:cache
  rules:
    - if: $CI_COMMIT_BRANCH
    - if: $CI_COMMIT_TAG

test:
  stage: test
  needs: [build]    # DAG: start when build completes
  image: $IMAGE
  script:
    - npm test
  rules:
    - if: $CI_COMMIT_BRANCH
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

### `template`
Create reusable templates for sharing across projects.

```yaml
# ci/templates/base.yml (template project)
.rules:merge-request:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"

.rules:main:
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

.rules:tags:
  rules:
    - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/

.node-cache:
  cache:
    key:
      files: [package-lock.json]
    paths: [.npm/]

.deploy:
  image: bitnami/kubectl:latest
  before_script:
    - kubectl config set-cluster k8s
        --server=$K8S_SERVER
        --certificate-authority-data=$K8S_CA
    - kubectl config set-credentials ci
        --token=$K8S_TOKEN
    - kubectl config set-context default --cluster=k8s --user=ci
    - kubectl config use-context default

# Usage in project .gitlab-ci.yml:
# include:
#   - project: myorg/ci-templates
#     ref: main
#     file: /ci/templates/base.yml
#
# deploy-staging:
#   extends: [.deploy, .rules:main]
#   script:
#     - kubectl set image deployment/myapp app=$IMAGE -n staging
```

### `secure`
Add GitLab security scanning templates.

```yaml
# Add to .gitlab-ci.yml
include:
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Dependency-Scanning.gitlab-ci.yml
  - template: Security/Container-Scanning.gitlab-ci.yml
  - template: Security/Secret-Detection.gitlab-ci.yml
  - template: Security/License-Scanning.gitlab-ci.yml

# Override container scanning to use our built image
container_scanning:
  needs: [build]
  variables:
    CS_IMAGE: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    CS_SEVERITY_THRESHOLD: HIGH
    CS_DOCKERFILE_PATH: Dockerfile

# DAST against staging (run after deploy-staging)
dast:
  stage: dast
  needs: [deploy-staging]
  variables:
    DAST_WEBSITE: $STAGING_URL
    DAST_FULL_SCAN_ENABLED: "false"
  rules:
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH
```

### `deploy`
Configure environment deployments with approval.

```yaml
# Deploy with environment, manual approval, and rollback
deploy-production:
  stage: deploy
  environment:
    name: production
    url: https://example.com
    deployment_tier: production
  image: bitnami/kubectl:latest
  needs:
    - job: deploy-staging
    - job: test
    - job: container_scanning
  script:
    # Rolling update
    - kubectl set image deployment/myapp
        app=$CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
        -n production
    # Wait for rollout
    - kubectl rollout status deployment/myapp
        -n production
        --timeout=10m
  after_script:
    # Notify on success or failure
    - curl -X POST $SLACK_WEBHOOK
        -d "{\"text\":\"Deployed $CI_COMMIT_SHORT_SHA to production: $CI_JOB_STATUS\"}"
  when: manual   # Require click in UI
  rules:
    - if: $CI_COMMIT_TAG =~ /^v\d+\.\d+\.\d+$/
      when: manual
```

## Common Pipeline Debugging

```bash
# Check pipeline status from CLI
glab ci view                                    # View current pipeline
glab ci status                                  # Status of latest pipeline
glab ci trace JOB_ID                            # Stream job logs

# Download job artifacts
glab ci artifact download --job build

# Retry failed job
glab ci retry JOB_ID

# Run specific job manually
glab ci run JOB_NAME

# Variables available to debug
# In job script, print CI_ variables:
# - run: env | grep CI_ | sort

# Check if MR pipeline vs branch pipeline
# CI_PIPELINE_SOURCE = "merge_request_event" for MR pipelines
# CI_PIPELINE_SOURCE = "push" for branch pipelines

# Common mistakes:
# - Using only: instead of rules: (legacy, unpredictable with MR pipelines)
# - Forgetting needs: with DAG (all stage jobs wait without it)
# - Not setting interruptible: true (old pipelines block new ones)
# - cache policy: pull-push on all jobs (slow; use pull for most, push only on build)
```
