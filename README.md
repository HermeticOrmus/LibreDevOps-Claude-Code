<p align="center">
  <img src="https://ormus.solutions/mascot/golden_swan.gif" alt="LibreDevOps Claude Code" width="128" style="image-rendering: pixelated;" />
</p>

<h1 align="center">LibreDevOps Claude Code</h1>

<p align="center">
  <em>DevOps engineering with Claude Code — 25 specialized plugins covering infrastructure, containers, CI/CD, observability, and cloud operations</em>
</p>

<p align="center">
  <a href="https://github.com/HermeticOrmus/LibreDevOps-Claude-Code/stargazers"><img src="https://img.shields.io/github/stars/HermeticOrmus/LibreDevOps-Claude-Code?style=flat-square&color=aa8142" alt="Stars" /></a>
  <a href="https://github.com/HermeticOrmus/LibreDevOps-Claude-Code/blob/main/LICENSE"><img src="https://img.shields.io/github/license/HermeticOrmus/LibreDevOps-Claude-Code?style=flat-square&color=aa8142" alt="License" /></a>
  <img src="https://img.shields.io/badge/DevOps-aa8142?style=flat-square&logo=kubernetes&logoColor=white" alt="DevOps" />
  <img src="https://img.shields.io/badge/Claude_Code-aa8142?style=flat-square&logo=anthropic&logoColor=white" alt="Claude Code" />
</p>

---

> **Skills, agents, commands, and workflows for DevOps engineering with Claude Code.**

DevOps is where YAML compounds. Generic AI coding produces config that "works in lab" then drowns under production load patterns the AI didn't anticipate. **LibreDevOps gives Claude Code the operational expertise to ship infrastructure that survives 3am incidents.**

Twenty-five domain plugins covering Kubernetes, Terraform, cloud platforms, CI/CD, observability, incident management, and the operational layer between them.

---

## Where LibreDevOps fits

| Claude Code component | LibreDevOps provides |
|---|---|
| **Plugins** | 25 plugins (k8s, Terraform, AWS/Azure/GCP, CI/CD, observability, more) |
| **Agents** | Specialist agents per plugin |
| **Commands** | Quick-access slash commands |
| **Skills** | Pattern libraries (manifests, modules, pipelines, alert rules) |

---

## The 25 plugins

### Infrastructure as code

| Plugin | Domain |
|---|---|
| **kubernetes-operations** ⭐ | Pod design, RBAC, NetworkPolicies, autoscaling, operator patterns |
| terraform-patterns | Modules, state, workspaces, drift detection |
| ansible-automation | Playbooks, roles, inventory, vault |
| configuration-management | Drift, GitOps, declarative vs imperative |
| docker-orchestration | Compose, Swarm, multi-arch builds |
| container-registry | ECR, GCR, ACR, Harbor, image signing |

### Cloud platforms

| Plugin | Domain |
|---|---|
| aws-infrastructure | VPCs, IAM, ELB, RDS, S3 patterns |
| azure-infrastructure | Resource groups, VNets, AKS, Azure AD |
| gcp-infrastructure | Projects, VPCs, GKE, IAM |
| serverless-patterns | Lambda, Cloud Functions, Functions, cold starts |
| service-mesh | Istio, Linkerd, Consul, observability |

### CI/CD

| Plugin | Domain |
|---|---|
| github-actions | Workflows, secrets, reusable actions, matrix builds |
| gitlab-ci | Pipelines, runners, environments, deployments |
| jenkins-pipelines | Declarative + scripted, plugins, shared libraries |
| release-management | Semver, changelogs, feature flags, canaries |

### Operations + reliability

| Plugin | Domain |
|---|---|
| monitoring-observability | Prometheus, Grafana, OpenTelemetry, SLI/SLO/SLA |
| log-management | Loki, Elastic, CloudWatch Logs, log routing |
| incident-management | PagerDuty, runbooks, postmortems, blameless |
| backup-disaster-recovery | RTO/RPO, point-in-time, cross-region |
| load-balancing | L4 vs L7, health checks, sticky sessions |
| networking-dns | DNS strategies, ingress, egress, NAT |

### Security + cost

| Plugin | Domain |
|---|---|
| secret-management | Vault, AWS Secrets Manager, sealed-secrets, rotation |
| infrastructure-security | IAM least-privilege, network segmentation, hardening |
| cost-optimization | RI/SP, spot, FinOps, tagging strategies |
| database-operations | Migrations, replication, backups, point-in-time recovery |

⭐ = depth-complete plugin. Remaining 24 are shell-improved.

---

## Quick start

```bash
git clone https://github.com/HermeticOrmus/LibreDevOps-Claude-Code.git ~/projects/LibreDevOps-Claude-Code
cd ~/projects/LibreDevOps-Claude-Code
./setup.sh
```

Then:

```
/k8s design a Pod for a high-traffic API. 4 replicas, autoscale 4-20 on CPU 70%, anti-affinity across zones, PDB minimum 2, resource limits, NetworkPolicy denying egress except to RDS
```

See [QUICK_START.md](QUICK_START.md).

---

## Learning paths

- **[Beginner](learning-paths/beginner.md)** — DevOps mindset, your first k8s deployment, GitOps
- **[Intermediate](learning-paths/intermediate.md)** — multi-environment promotion, observability, incident response
- **[Advanced](learning-paths/advanced.md)** — multi-region, FinOps, platform engineering, SRE

## Compatibility

Kubernetes 1.27+, Terraform 1.5+, all three major clouds, OCI, on-prem K8s.

## Contributing

PRs especially welcome for: more cloud depth per provider, regional pattern variations, real incident case studies, k8s operator examples. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT.

---

## Part of the Libre Open-Source Stack for Claude Code

This repository is part of a growing family of open-source toolkits for Claude Code.

### Libre suite — comprehensive plugin bundles

- [LibreUIUX-Claude-Code](https://github.com/HermeticOrmus/LibreUIUX-Claude-Code) — UI/UX development (152 agents, 70 plugins, 76 commands, 74 skills)
- [LibreArch-Claude-Code](https://github.com/HermeticOrmus/LibreArch-Claude-Code) — Software architecture and system design
- [LibreCopy-Claude-Code](https://github.com/HermeticOrmus/LibreCopy-Claude-Code) — Technical writing and documentation engineering
- [LibreEmbed-Claude-Code](https://github.com/HermeticOrmus/LibreEmbed-Claude-Code) — Embedded systems, firmware, and IoT development
- [LibreFinTech-Claude-Code](https://github.com/HermeticOrmus/LibreFinTech-Claude-Code) — Financial technology development
- [LibreGEO-Claude-Code](https://github.com/HermeticOrmus/LibreGEO-Claude-Code) — AI-search optimization (ChatGPT, Perplexity, Gemini, Google AI Overviews)
- [LibreGameDev-Claude-Code](https://github.com/HermeticOrmus/LibreGameDev-Claude-Code) — Game development across Godot, Unity, Unreal
- [LibreMLOps-Claude-Code](https://github.com/HermeticOrmus/LibreMLOps-Claude-Code) — ML engineering and AI operations
- [LibreMobileDev-Claude-Code](https://github.com/HermeticOrmus/LibreMobileDev-Claude-Code) — Mobile app development (Flutter, React Native, native iOS, native Android)
- [LibreSecOps-Claude-Code](https://github.com/HermeticOrmus/LibreSecOps-Claude-Code) — Security operations
- [LibreSessionFlow-Claude-Code](https://github.com/HermeticOrmus/LibreSessionFlow-Claude-Code) — Session lifecycle: handoff, pickup, absorb, explore, close

### Skills mini-repos — single CLAUDE.md drop-ins

- [vibe-engineer-skills](https://github.com/HermeticOrmus/vibe-engineer-skills) — Direct AI codegen well: hypothesis before help, scoped prompts, validate before accepting
- [markdown-discipline-skills](https://github.com/HermeticOrmus/markdown-discipline-skills) — Strip AI-slop from markdown (no em dashes, no marketing fluff)
- [shell-safety-skills](https://github.com/HermeticOrmus/shell-safety-skills) — `set -euo pipefail` discipline plus 15 failure-mode examples
- [commit-standard-skills](https://github.com/HermeticOrmus/commit-standard-skills) — Ormus Commit Standard v1.0 plus commit-msg hook and commitlint
- [unwoke-skills](https://github.com/HermeticOrmus/unwoke-skills) — Strip AI theater (ten sins to eliminate, symmetric engagement)
- [python-conventions-skills](https://github.com/HermeticOrmus/python-conventions-skills) — Modern Python 3.11+ (types, pathlib, async, ruff, mypy, uv)
- [typescript-conventions-skills](https://github.com/HermeticOrmus/typescript-conventions-skills) — TypeScript strict mode, discriminated unions, Result types
- [hermetic-laws-skills](https://github.com/HermeticOrmus/hermetic-laws-skills) — Seven Hermetic Principles applied to engineering
- [riper-workflow-skills](https://github.com/HermeticOrmus/riper-workflow-skills) — Research / Innovate / Plan / Execute / Review systematic dev
- [six-day-cycle-skills](https://github.com/HermeticOrmus/six-day-cycle-skills) — Sustainable shipping cadence with mandatory rest
- [token-optimization-skills](https://github.com/HermeticOrmus/token-optimization-skills) — Claude Code token and context optimization
- [osint-skills](https://github.com/HermeticOrmus/osint-skills) — OSINT research methodology (multi-wave investigative spiral)
- [calcinate-skills](https://github.com/HermeticOrmus/calcinate-skills) — Stage 1 of the Magnum Opus (burn project bloat)
- [claude-md-overhaul-skills](https://github.com/HermeticOrmus/claude-md-overhaul-skills) — Audit CLAUDE.md and MEMORY.md against caps
- [session-handoff-skills](https://github.com/HermeticOrmus/session-handoff-skills) — Session handoff and pickup discipline
- [naming-skills](https://github.com/HermeticOrmus/naming-skills) — Product naming methodology (mine the brand's vocabulary)
- [magnum-opus-skills](https://github.com/HermeticOrmus/magnum-opus-skills) — Seven-stage alchemy applied to project transformation
- [mem-search-skills](https://github.com/HermeticOrmus/mem-search-skills) — Search claude-mem cross-session memory: search, filter, fetch
- [hypothesis-debugging-skills](https://github.com/HermeticOrmus/hypothesis-debugging-skills) — Hypothesis-driven debugging: reproduce, isolate, test, fix
- [vibe-proof-skills](https://github.com/HermeticOrmus/vibe-proof-skills) — Security hardening for vibe-coded full-stack apps
- [tdd-skills](https://github.com/HermeticOrmus/tdd-skills) — Test-driven development (Red-Green-Refactor) for JS/TS and Python
- [mars-skills](https://github.com/HermeticOrmus/mars-skills) — Production-readiness audit: the five mortal sins of vibe-coded MVPs
- [git-workflow-skills](https://github.com/HermeticOrmus/git-workflow-skills) — Clean git workflow: branch, atomic commits, reviewable PRs
- [code-review-skills](https://github.com/HermeticOrmus/code-review-skills) — Domain-aware code review: classify the code, then focus
- [explore-code-skills](https://github.com/HermeticOrmus/explore-code-skills) — Understand an unfamiliar codebase fast
- [dx-audit-skills](https://github.com/HermeticOrmus/dx-audit-skills) — Audit developer experience: docs, onboarding, tooling friction
- [setup-env-skills](https://github.com/HermeticOrmus/setup-env-skills) — Set up a project's development environment
- [automate-skills](https://github.com/HermeticOrmus/automate-skills) — Turn repetitive tasks into reliable automation scripts
- [quick-fix-skills](https://github.com/HermeticOrmus/quick-fix-skills) — Fast troubleshooting for common issues
- [prime-context-skills](https://github.com/HermeticOrmus/prime-context-skills) — Prime project context at the start of a session
- [auto-docs-skills](https://github.com/HermeticOrmus/auto-docs-skills) — Generate and maintain project documentation
- [learning-skills](https://github.com/HermeticOrmus/learning-skills) — Learn any technology: roadmaps, explanations, practice, cheatsheets, comparisons
- [linux-sysadmin-skills](https://github.com/HermeticOrmus/linux-sysadmin-skills) — Linux system administration: security, performance, diagnostics, monitoring, maintenance

### Template source

- [andrej-karpathy-skills](https://github.com/HermeticOrmus/andrej-karpathy-skills) — the canonical single-file CLAUDE.md pattern (fork of jiayuan_jy's original)

Star the family, not just one — that's how the suite stays coherent.
