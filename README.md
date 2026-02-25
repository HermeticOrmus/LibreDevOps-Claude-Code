<p align="center">
  <h1 align="center">LibreDevOps-Claude-Code</h1>
  <p align="center">
    <img src="https://img.shields.io/badge/plugins-25-cb4b16?style=flat-square" alt="Plugins: 25" />
    <img src="https://img.shields.io/badge/license-MIT-cb4b16?style=flat-square" alt="License: MIT" />
    <img src="https://img.shields.io/badge/claude--code-plugins-cb4b16?style=flat-square" alt="Claude Code Plugins" />
  </p>
</p>

A curated collection of Claude Code plugins for DevOps engineering, infrastructure automation, and CI/CD pipelines. From Terraform to Kubernetes, monitoring to incident response.

---

## What This Is

LibreDevOps is a **plugin collection** that gives Claude Code deep expertise in DevOps and infrastructure engineering. Each plugin provides an **agent** (specialized persona), a **command** (slash command interface), and a **skill** (knowledge base and patterns) -- all designed for production-grade infrastructure work.

This is not tutorial-grade content. Every pattern, template, and recommendation accounts for state management, secret handling, failure modes, and operational reality.

---

## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/HermeticOrmus/LibreDevOps-Claude-Code.git
```

### 2. Copy a plugin into your project

```bash
# Example: Add Terraform patterns to your project
cp -r LibreDevOps-Claude-Code/plugins/terraform-patterns/.claude/ your-project/.claude/

# Or cherry-pick specific components
cp LibreDevOps-Claude-Code/plugins/terraform-patterns/agents/terraform-engineer/AGENT.md \
   your-project/.claude/agents/terraform-engineer.md
```

### 3. Copy the DevOps CLAUDE.md template

```bash
cp LibreDevOps-Claude-Code/templates/CLAUDE.md your-project/CLAUDE.md
# Edit to match your infrastructure stack
```

### 4. Install hooks (optional)

```bash
cp LibreDevOps-Claude-Code/hooks/*.sh your-project/.claude/hooks/
chmod 755 your-project/.claude/hooks/*.sh
```

---

## Plugins

| # | Plugin | Description | Category |
|---|--------|-------------|----------|
| 1 | [ansible-automation](plugins/ansible-automation/) | Ansible playbooks, roles, inventory management | IaC |
| 2 | [aws-infrastructure](plugins/aws-infrastructure/) | AWS services, CloudFormation, CDK patterns | Cloud |
| 3 | [azure-infrastructure](plugins/azure-infrastructure/) | Azure services, ARM templates, Bicep | Cloud |
| 4 | [backup-disaster-recovery](plugins/backup-disaster-recovery/) | Backup strategies, DR planning, RTO/RPO | Operations |
| 5 | [configuration-management](plugins/configuration-management/) | Config management, environment parity, feature flags | IaC |
| 6 | [container-registry](plugins/container-registry/) | Container image management, scanning, signing | Containers |
| 7 | [cost-optimization](plugins/cost-optimization/) | Cloud cost analysis, right-sizing, FinOps | Operations |
| 8 | [database-operations](plugins/database-operations/) | DB migrations, backups, replication, scaling | Operations |
| 9 | [docker-orchestration](plugins/docker-orchestration/) | Docker Compose, multi-stage builds, optimization | Containers |
| 10 | [gcp-infrastructure](plugins/gcp-infrastructure/) | GCP services, Deployment Manager, Cloud Build | Cloud |
| 11 | [github-actions](plugins/github-actions/) | GitHub Actions workflows, reusable actions, matrix builds | CI/CD |
| 12 | [gitlab-ci](plugins/gitlab-ci/) | GitLab CI/CD pipelines, runners, environments | CI/CD |
| 13 | [incident-management](plugins/incident-management/) | Incident response, postmortems, on-call procedures | Operations |
| 14 | [infrastructure-security](plugins/infrastructure-security/) | Infrastructure hardening, CIS benchmarks, compliance | Security |
| 15 | [jenkins-pipelines](plugins/jenkins-pipelines/) | Jenkins declarative/scripted pipelines, shared libraries | CI/CD |
| 16 | [kubernetes-operations](plugins/kubernetes-operations/) | K8s deployments, Helm charts, operators, troubleshooting | Containers |
| 17 | [load-balancing](plugins/load-balancing/) | Load balancer config, traffic management, CDN | Networking |
| 18 | [log-management](plugins/log-management/) | Centralized logging, ELK/Loki, log analysis | Observability |
| 19 | [monitoring-observability](plugins/monitoring-observability/) | Prometheus, Grafana, tracing, SLOs/SLIs | Observability |
| 20 | [networking-dns](plugins/networking-dns/) | Network architecture, DNS management, VPN, firewalls | Networking |
| 21 | [release-management](plugins/release-management/) | Release strategies, blue-green, canary, feature flags | CI/CD |
| 22 | [secret-management](plugins/secret-management/) | Vault, secret rotation, encryption, key management | Security |
| 23 | [serverless-patterns](plugins/serverless-patterns/) | Lambda, Cloud Functions, serverless frameworks | Cloud |
| 24 | [service-mesh](plugins/service-mesh/) | Istio, Linkerd, mTLS, traffic policies | Networking |
| 25 | [terraform-patterns](plugins/terraform-patterns/) | Terraform modules, state management, workspaces | IaC |

---

## Architecture

```
LibreDevOps-Claude-Code/
|
|-- plugins/                    # 25 DevOps domain plugins
|   |-- {plugin-name}/
|   |   |-- README.md           # Plugin overview and usage
|   |   |-- agents/             # Specialized agent definitions
|   |   |   +-- {name}/AGENT.md
|   |   |-- commands/           # Slash command definitions
|   |   |   +-- {name}/COMMAND.md
|   |   +-- skills/             # Knowledge base and patterns
|   |       +-- {name}/SKILL.md
|   +-- ...
|
|-- learning-paths/             # Progressive skill building
|   |-- beginner.md             # Docker, basic CI/CD, first IaC
|   |-- intermediate.md         # Kubernetes, Terraform, monitoring
|   +-- advanced.md             # Multi-cloud, GitOps, chaos engineering
|
|-- hooks/                      # Session automation
|   |-- session-start.sh        # Infrastructure context detection
|   |-- pre-tool-use.sh         # Validation and secret scanning
|   +-- post-tool-use.sh        # Drift detection and compliance
|
|-- templates/                  # Project configuration templates
|   +-- CLAUDE.md               # DevOps-focused CLAUDE.md template
|
+-- .github/                    # Repository management
    |-- FUNDING.yml
    |-- PULL_REQUEST_TEMPLATE.md
    +-- ISSUE_TEMPLATE/
```

### Plugin Anatomy

Each plugin provides three components that work together:

- **Agent** (`AGENT.md`) -- A specialized persona with defined expertise, behavior patterns, and output formats. Use when you need deep domain knowledge and structured guidance.
- **Command** (`COMMAND.md`) -- A slash command interface for common operations. Use for quick, repeatable tasks.
- **Skill** (`SKILL.md`) -- A knowledge base of patterns, anti-patterns, and references. Use as a reference library for best practices.

### How Plugins Compose

Plugins are designed to be used individually or combined. A typical infrastructure project might use:

- `terraform-patterns` + `aws-infrastructure` for IaC on AWS
- `github-actions` + `release-management` for CI/CD
- `monitoring-observability` + `incident-management` for operations
- `secret-management` + `infrastructure-security` for security posture

---

## Learning Paths

| Path | Audience | Topics |
|------|----------|--------|
| [Beginner](learning-paths/beginner.md) | New to DevOps | Docker basics, first CI/CD pipeline, intro to IaC |
| [Intermediate](learning-paths/intermediate.md) | Working with infra | Kubernetes, Terraform modules, monitoring stacks |
| [Advanced](learning-paths/advanced.md) | Platform engineers | Multi-cloud, service mesh, GitOps, chaos engineering |

---

## Hooks

The hooks directory contains automation scripts for Claude Code sessions:

| Hook | Purpose |
|------|---------|
| `session-start.sh` | Detects infrastructure context -- IaC tools, cloud providers, container configs |
| `pre-tool-use.sh` | Validates IaC files, scans for secrets before applies |
| `post-tool-use.sh` | Checks for drift, verifies compliance, flags issues |

Install by copying to `.claude/hooks/` in your project and making executable.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines. Key principles:

- **Production-grade only** -- No tutorial-grade configs that only work on fresh accounts
- **No hardcoded secrets** -- Use placeholders, environment variables, or secret managers
- **Test what you contribute** -- Validate in a real environment
- **Document the blast radius** -- State the scope of impact for every infrastructure change

---

## License

[MIT](LICENSE) -- Copyright (c) 2025-2026 Hermetic Ormus

---

**Build what elevates. Reject what degrades. Share what empowers.**
