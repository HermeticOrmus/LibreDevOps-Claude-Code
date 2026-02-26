# GitHub Actions Plugin

Workflows, reusable workflows, composite actions, OIDC cloud auth, matrix builds, and security hardening.

## Components

- **Agent**: `gha-engineer` -- Designs workflow triggers, job structure, OIDC auth, composite actions, runner selection
- **Command**: `/gha` -- Creates workflows, reusable workflow definitions, security scans, debug sessions
- **Skill**: `gha-patterns` -- Complete CI/CD pipeline, dependency caching, expressions cheatsheet, ARC self-hosted runners

## Quick Reference

```bash
# Lint workflows locally
actionlint .github/workflows/

# Run workflow locally
act push
act pull_request -j specific-job

# Check workflow permissions
gh api /repos/ORG/REPO/actions/permissions

# View workflow runs
gh run list
gh run view RUN_ID --log
```

## OIDC vs Secrets

Never store cloud credentials as GitHub Secrets for deployment. Use OIDC:

```yaml
# AWS OIDC (no stored keys)
permissions:
  id-token: write
steps:
  - uses: aws-actions/configure-aws-credentials@v4
    with:
      role-to-assume: arn:aws:iam::ACCOUNT:role/GHARole
      aws-region: us-east-1
```

Trust policy on the IAM role must include GitHub's OIDC provider and scope to specific repos/branches.

## Key Patterns

**Reusable workflows** for shared build/deploy pipelines across repos. Use `workflow_call` trigger, define `inputs` and `outputs`, call with `uses: org/repo/.github/workflows/file.yml@ref`.

**Composite actions** for multi-step sequences within a job. Define in `.github/actions/name/action.yml`. Use `runs: using: composite`.

**Matrix strategy** for multi-version/multi-platform testing. Always set `fail-fast: false` when you want all matrix combinations to run regardless of individual failures.

**Minimal permissions**: Start with `permissions: {}` at workflow level. Add only what each job needs. `contents: read` for checkout, `id-token: write` for OIDC, `packages: write` for GHCR push.

## Related Plugins

- [container-registry](../container-registry/) -- GHCR push, ECR push, Cosign signing in Actions
- [aws-infrastructure](../aws-infrastructure/) -- AWS OIDC trust policy setup
- [gcp-infrastructure](../gcp-infrastructure/) -- GCP Workload Identity Pool for Actions
- [terraform-patterns](../terraform-patterns/) -- Atlantis vs GitHub Actions for Terraform
