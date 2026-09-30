# LibreDevOps Hooks Plugin

> Optional Claude Code hooks for infrastructure work: project context when a session opens, a confirmation before edits to secret or state files, and infrastructure checks after each edit.

This plugin is optional. The other LibreDevOps plugins work without it. Install it when you want Claude to notice infrastructure problems while it edits, not only when you ask for a review.

## Install

```
/plugin marketplace add HermeticOrmus/LibreDevOps-Claude-Code
/plugin install libre-devops-hooks@libre-devops
```

Or from a terminal: `claude plugin install libre-devops-hooks@libre-devops`. Restart Claude Code after installing. Remove it with `claude plugin uninstall libre-devops-hooks@libre-devops`.

Requirements: `bash` and `jq`. Without `jq` the hooks exit silently and do nothing.

## What each hook does

| Event | Script | Behavior |
|-------|--------|----------|
| `SessionStart` (startup, resume, clear, compact) | `hooks/session-start.sh` | In a project with Terraform, Pulumi, CloudFormation, CDK, Ansible, Packer, CI/CD configs, Docker, Kubernetes, Helm, Kustomize, or monitoring configs, prints one line of context: tools found, cloud providers, security tooling, the top warnings (state committed to git, no remote backend, Dockerfile running as root, missing `.gitignore` entries), and which LibreDevOps plugins fit. Prints nothing in other projects. |
| `PreToolUse` (Edit, Write, MultiEdit) | `hooks/pre-tool-use.sh` | Asks you to confirm before Claude edits Terraform state, cloud credential files, Ansible Vault password files, `.env` files (not `.env.example`), private keys and keystores, or config files named after secrets. Every other edit passes through silently. |
| `PostToolUse` (Edit, Write, MultiEdit) | `hooks/post-tool-use.sh` | Checks the file just written and, only when something is wrong, hands the findings to Claude: Terraform (formatting, hardcoded secrets, missing backend, 0.0.0.0/0 ingress, missing encryption, wildcard IAM, public databases, IMDSv2, tags, provider constraints, replacement-prone changes), Kubernetes (Secrets, privileged or host access, resources, probes, root, `:latest`, single replicas, cluster-admin), Dockerfiles, CI/CD pipelines, Docker Compose, Ansible, secrets in any file, and `.gitignore` coverage. |

## Design

- Hook input is read as JSON from stdin with `jq` (`tool_name`, `tool_input.file_path`, `cwd`), which is how Claude Code delivers it.
- Scripts are referenced through `${CLAUDE_PLUGIN_ROOT}`, so they run from wherever Claude Code installed the plugin.
- Nothing is written to disk: no log files, no caches.
- Nothing is blocked. The PreToolUse hook returns `ask`, so you decide; the PostToolUse hook only adds context.
- The checks are pattern matches, not a scanner. Treat a finding as a prompt to look, and pair these hooks with Checkov, tfsec, Trivy, or gitleaks in CI for real coverage.

## Related plugins

| Plugin | Relationship |
|--------|-------------|
| `infrastructure-security` | Full IaC security review and hardening beyond these quick checks. |
| `secret-management` | Where secrets should live instead of the files this plugin guards. |
| `terraform-patterns` | Remote state, module structure, and plan review practices the Terraform checks point to. |
