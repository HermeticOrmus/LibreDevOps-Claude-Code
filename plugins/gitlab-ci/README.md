# GitLab CI Plugin

.gitlab-ci.yml, DAG pipelines with needs:, GitLab environments, SAST/DAST scanning, merge request pipelines, and shared templates.

## Components

- **Agent**: `gitlab-ci-engineer` -- Designs stages, DAG with `needs:`, rules, environments, cache, security templates
- **Command**: `/gitlab-ci` -- Generates pipelines, reusable templates, security scanning, deployment jobs
- **Skill**: `gitlab-ci-patterns` -- Complete pipeline examples, MR pipelines, dynamic child pipelines, variable reference

## Quick Reference

```bash
# GitLab CLI (glab)
glab ci view              # View current pipeline in browser
glab ci status            # Latest pipeline status
glab ci trace JOB_ID      # Stream job logs
glab ci retry JOB_ID      # Retry failed job
glab ci artifact download --job build

# Check pipeline source in job
# $CI_PIPELINE_SOURCE = "merge_request_event" | "push" | "schedule" | "web"
# $CI_COMMIT_BRANCH vs $CI_MERGE_REQUEST_TARGET_BRANCH_NAME
```

## Key Patterns

**Always use `rules:` not `only:/except:`**. `only/except` has undocumented interactions with MR pipelines. `rules:` is explicit and composable.

**Use `needs:` for DAG pipelines**. Without `needs:`, every job in a stage waits for ALL jobs in the previous stage. With `needs:`, jobs start as soon as their specific dependencies complete. This can reduce pipeline duration by 50%+.

**`needs: []` for parallelism**: A job with `needs: []` starts at the same time as the first stage. Use for jobs that don't need build artifacts (linting, secrets scanning).

**Cache vs artifacts**: Cache persists between pipeline runs (dependency install). Artifacts pass files within the same pipeline between jobs. Don't use cache for artifact-like data.

**Protected CI/CD variables**: Mark production secrets as `Protected` in GitLab CI/CD settings. Protected variables only run on protected branches (main, master, tags). Prevents staging secrets from reaching production pipelines.

## Related Plugins

- [container-registry](../container-registry/) -- GitLab Container Registry push and scanning
- [kubernetes-operations](../kubernetes-operations/) -- kubectl in GitLab CI deploy jobs
- [infrastructure-security](../infrastructure-security/) -- SAST/DAST result interpretation
- [release-management](../release-management/) -- GitLab environments and deployment tracking
