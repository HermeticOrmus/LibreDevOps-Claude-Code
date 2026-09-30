# /gha

Create GitHub Actions workflows, reusable workflows, composite actions, and OIDC cloud auth.

## Usage

```
/gha create|reuse|secure|debug [options]
```

## Actions

### `create`
Generate a workflow for a common CI/CD pattern.

```yaml
# Node.js CI with test, lint, build
name: CI
on:
  push: { branches: [main] }
  pull_request: { branches: [main] }

permissions:
  contents: read

jobs:
  ci:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: ['18', '20', '22']
    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: npm

      - run: npm ci
      - run: npm run lint
      - run: npm run type-check
      - run: npm test -- --coverage --ci

      - uses: actions/upload-artifact@v4
        if: matrix.node-version == '20'  # Upload coverage once
        with:
          name: coverage-report
          path: coverage/
          retention-days: 5
```

### `reuse`
Create or call reusable workflows.

```yaml
# Caller workflow
name: Deploy
on:
  push: { branches: [main] }

jobs:
  build:
    uses: myorg/workflows/.github/workflows/docker-build.yml@main
    with:
      image-name: ghcr.io/myorg/myapp
      push: true
    secrets: inherit   # Pass all caller secrets to reusable workflow
    permissions:
      contents: read
      packages: write
      id-token: write

  deploy:
    needs: build
    uses: myorg/workflows/.github/workflows/deploy-ecs.yml@main
    with:
      environment: production
      image-digest: ${{ needs.build.outputs.digest }}
    secrets:
      aws-role-arn: ${{ secrets.AWS_DEPLOY_ROLE_ARN }}
```

```yaml
# Reusable workflow definition
# myorg/workflows/.github/workflows/docker-build.yml
name: Docker Build
on:
  workflow_call:
    inputs:
      image-name:
        required: true
        type: string
      push:
        type: boolean
        default: false
      platforms:
        type: string
        default: linux/amd64,linux/arm64
    outputs:
      digest:
        value: ${{ jobs.build.outputs.digest }}

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      digest: ${{ steps.build.outputs.digest }}
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - id: build
        uses: docker/build-push-action@v5
        with:
          push: ${{ inputs.push }}
          platforms: ${{ inputs.platforms }}
          tags: ${{ inputs.image-name }}:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
```

### `secure`
Add security checks and harden workflow permissions.

```yaml
# Security-hardened workflow template
name: Secure Build
on:
  pull_request:
    branches: [main]

# Minimal permissions at workflow level
permissions:
  contents: read

jobs:
  security:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      security-events: write    # For SARIF upload only

    steps:
      - uses: actions/checkout@v4
        with:
          persist-credentials: false   # Don't write GitHub token to git config

      # Dependency vulnerability scan
      - name: Run npm audit
        run: npm audit --audit-level=high
        continue-on-error: true

      # Static analysis
      - uses: github/codeql-action/init@v3
        with:
          languages: javascript
      - uses: github/codeql-action/analyze@v3

      # Container scan
      - uses: aquasecurity/trivy-action@master
        with:
          scan-type: fs
          format: sarif
          output: trivy.sarif
          severity: HIGH,CRITICAL
          exit-code: '1'

      - uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: trivy.sarif

      # Secret scanning (gitleaks)
      - name: Scan for secrets
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### `debug`
Troubleshoot failing workflows.

```yaml
# Interactive debug session via tmate
- name: SSH into runner (debug)
  uses: mxschmitt/action-tmate@v3
  if: ${{ failure() }}      # Only open when job fails
  timeout-minutes: 15
  with:
    limit-access-to-actor: true  # Only workflow actor can connect

# Print all GitHub context
- name: Dump contexts
  env:
    GITHUB_CONTEXT: ${{ toJson(github) }}
    NEEDS_CONTEXT: ${{ toJson(needs) }}
  run: |
    echo "=== GITHUB CONTEXT ===" && echo "$GITHUB_CONTEXT" | jq .
    echo "=== NEEDS CONTEXT ===" && echo "$NEEDS_CONTEXT" | jq .
```

## Workflow Validation Commands

```bash
# Validate workflow syntax locally (requires actionlint)
actionlint .github/workflows/ci.yml

# Install actionlint
brew install actionlint  # macOS
# or
curl -sSfL https://raw.githubusercontent.com/rhysd/actionlint/main/scripts/download-actionlint.bash | bash

# Validate all workflows in repo
actionlint

# Run workflow locally with act
act push                           # Simulate push event
act pull_request                   # Simulate PR event
act workflow_dispatch               # Simulate manual trigger
act -j specific-job-name           # Run specific job
act --list                          # List available jobs

# Check required permissions for workflow
# GitHub API: GET /repos/{owner}/{repo}/actions/permissions
gh api /repos/myorg/myrepo/actions/permissions
```
