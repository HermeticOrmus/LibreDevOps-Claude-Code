<p align="center">
  <img src="https://ormus.solutions/mascot/pixellab_liquid_to_branch.gif" alt="LibreDevOps Claude Code" width="128" style="image-rendering: pixelated;" />
</p>

<h1 align="center">LibreDevOps Claude Code</h1>

<p align="center">
  <em>DevOps engineering with Claude Code — 25 specialized plugins plus optional hooks, covering infrastructure, containers, CI/CD, observability, and cloud operations</em>
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

Twenty-five domain plugins covering Kubernetes, Terraform, cloud platforms, CI/CD, observability, incident management, and the operational layer between them, plus an optional hooks plugin that checks infrastructure files as Claude edits them. Every plugin installs through the Claude Code plugin system.

---

## Where LibreDevOps fits

| Claude Code component | LibreDevOps provides |
|---|---|
| **Plugins** | 25 domain plugins (k8s, Terraform, AWS/Azure/GCP, CI/CD, observability, more) plus `libre-devops-hooks` |
| **Agents** | 25 specialist agents, one per domain plugin |
| **Commands** | 24 slash commands (every domain plugin except log-management) |
| **Skills** | 26 pattern libraries (manifests, modules, pipelines, alert rules) |
| **Hooks** | Optional: session context, a confirmation before edits to secret and state files, post-edit infrastructure checks |

---

## The 25 plugins

Each domain plugin ships one agent, one slash command (log-management has none), and one or two skills. Install only the ones you use.

### Infrastructure as code

| Plugin | Covers | Agent | Command |
|---|---|---|---|
| **kubernetes-operations** ⭐ | Pod design, probes, RBAC, NetworkPolicies, HPA and KEDA, Helm, pod failure diagnosis | `k8s-engineer` | `/k8s` |
| terraform-patterns | Terraform and OpenTofu modules, remote state, for_each, Terragrunt, drift, CI/CD | `terraform-engineer` | `/terraform` |
| ansible-automation | Idempotent playbooks and roles, inventories, variable precedence, Vault, Molecule | `ansible-engineer` | `/ansible` |
| configuration-management | 12-factor config, SSM Parameter Store, Consul, etcd, feature flags, schema validation | `config-manager` | `/config` |
| docker-orchestration | Multi-stage Dockerfiles, BuildKit caching, compose health checks, non-root and distroless images | `docker-engineer` | `/docker` |
| container-registry | ECR, GHCR, Harbor, Trivy scanning, Cosign signing, multi-arch builds, SBOMs, lifecycle policies | `registry-manager` | `/registry` |

### Cloud platforms

| Plugin | Covers | Agent | Command |
|---|---|---|---|
| aws-infrastructure | CDK and CloudFormation, VPC, IAM, ECS Fargate, RDS, CloudFront, Well-Architected | `aws-architect` | `/aws` |
| azure-infrastructure | Bicep and ARM, AKS, Key Vault, Azure RBAC, Azure DevOps, Azure Policy, landing zones | `azure-architect` | `/azure` |
| gcp-infrastructure | Terraform on GCP, GKE, Cloud Run, Cloud SQL, Workload Identity, Cloud Armor | `gcp-architect` | `/gcp` |
| serverless-patterns | AWS Lambda, API Gateway, Step Functions, EventBridge, SQS/SNS, DynamoDB, cold starts | `serverless-architect` | `/serverless` |
| service-mesh | Istio, Linkerd, Envoy, mTLS, traffic routing, circuit breaking, authorization policies | `mesh-engineer` | `/service-mesh` |

### CI/CD

| Plugin | Covers | Agent | Command |
|---|---|---|---|
| github-actions | Workflows, reusable workflows, composite actions, matrix builds, OIDC, SHA pinning, runners | `gha-engineer` | `/gha` |
| gitlab-ci | `rules:`, DAG `needs:`, merge request pipelines, environments, templates, SAST/DAST | `gitlab-ci-engineer` | `/gitlab-ci` |
| jenkins-pipelines | Declarative Jenkinsfiles, shared libraries, Kubernetes agents, JCasC, pipeline tests | `jenkins-engineer` | `/jenkins` |
| release-management | Blue/green, canary with Argo Rollouts, ArgoCD GitOps, Helm releases, semver, rollback | `release-manager` | `/release` |

### Operations + reliability

| Plugin | Covers | Agent | Command |
|---|---|---|---|
| monitoring-observability | Prometheus, PromQL, Grafana, Thanos, OpenTelemetry, SLOs and burn rate alerts | `observability-engineer` | `/monitor` |
| log-management | Structured logging, Fluent Bit, Fluentd, Vector, Loki, OpenSearch retention, log alerts | `log-engineer` | none |
| incident-management | Severity levels, on-call, status updates, SLO burn rate alerts, runbooks, postmortems | `incident-commander` | `/incident` |
| backup-disaster-recovery | RTO/RPO, 3-2-1 backups, pgBackRest, Velero, AWS Backup, DR runbooks and drills | `dr-planner` | `/backup-plan` |
| load-balancing | NGINX, HAProxy, AWS ALB/NLB, ingress controllers, TLS termination, rate limiting, canaries | `lb-engineer` | `/load-balance` |
| networking-dns | VPC and CIDR planning, Route53, Transit Gateway, security groups, CoreDNS, ExternalDNS | `network-engineer` | `/network` |

### Security + cost

| Plugin | Covers | Agent | Command |
|---|---|---|---|
| secret-management | Vault, AWS Secrets Manager, External Secrets Operator, Sealed Secrets, SOPS, rotation | `secrets-engineer` | `/secrets` |
| infrastructure-security | CIS Benchmarks, Checkov, Vault, security groups, GuardDuty, CloudTrail analysis | `infrasec-engineer` | `/infrasec` |
| cost-optimization | FinOps Framework, rightsizing, Savings Plans and Spot, S3 and NAT costs, Infracost, tagging | `finops-analyst` | `/cost-optimize` |
| database-operations | PostgreSQL EXPLAIN ANALYZE, indexing, autovacuum, pgBouncer, replication, migrations | `dba-specialist` | `/db-ops` |

### Optional hooks

| Plugin | Covers |
|---|---|
| libre-devops-hooks | One line of project context at session start in infrastructure repos; asks before Claude edits Terraform state, credential, `.env`, key, or secrets files; checks Terraform, Kubernetes, Dockerfiles, CI/CD, Compose, and Ansible files after each edit. See [its README](plugins/libre-devops-hooks/README.md). |

⭐ = depth-complete plugin. Remaining 24 are shell-improved.

---

## Quick start

### Install from Claude Code

```
/plugin marketplace add HermeticOrmus/LibreDevOps-Claude-Code
/plugin install kubernetes-operations@libre-devops
```

The same from a terminal:

```bash
claude plugin marketplace add HermeticOrmus/LibreDevOps-Claude-Code
claude plugin install kubernetes-operations@libre-devops
```

Install any other plugin the same way with `<plugin>@libre-devops`, using the names in the tables above. Restart Claude Code after installing.

Optional hooks: `/plugin install libre-devops-hooks@libre-devops` adds project context at session start, asks before edits to secret and Terraform state files, and checks infrastructure files after each edit (needs `jq`).

### Install in Grok Build

Grok Build reads the same plugin folders. Add the marketplace, then install any plugin by name:

```bash
grok plugin marketplace add HermeticOrmus/LibreDevOps-Claude-Code
grok plugin install kubernetes-operations@LibreDevOps-Claude-Code --trust
```

Or install one plugin straight from its folder, without adding the marketplace:

```bash
grok plugin install HermeticOrmus/LibreDevOps-Claude-Code#plugins/kubernetes-operations --trust
```

`--trust` confirms you trust the source; without it Grok shows what the plugin would activate and stops. Start a new Grok session to load what you installed. From a clone, `./setup.sh --grok` installs the whole pack through the `grok` CLI. The `libre-devops-hooks` plugin uses a hook format Grok supports, but it has not been verified in a live Grok session (see the [ledger](LEDGER.md)).

### Install from a clone

```bash
git clone https://github.com/HermeticOrmus/LibreDevOps-Claude-Code.git ~/projects/LibreDevOps-Claude-Code
cd ~/projects/LibreDevOps-Claude-Code
./setup.sh
```

`./setup.sh` registers the clone as the `libre-devops` marketplace and installs all 26 plugins, including `libre-devops-hooks`, through the Claude Code CLI. Pick plugins with `./setup.sh --only kubernetes-operations,terraform-patterns` (leave `libre-devops-hooks` out to skip the hooks), see every name with `./setup.sh --list`, and remove the pack with `./setup.sh --uninstall`. Add `--grok` to install through Grok Build instead; it works with `--list`, `--only`, and `--uninstall`, and needs `grok` and `jq`.

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

Installs as a Claude Code plugin marketplace; tested with Claude Code 2.1.285. The hooks plugin needs `bash` and `jq`.

Also installs as a Grok Build plugin marketplace; tested with grok 1.0.44. The hooks plugin has not been verified in a live Grok session.

## Feedback

Starred this? Tell us what worked and what is missing: [open a feedback issue](https://github.com/HermeticOrmus/LibreDevOps-Claude-Code/issues/new?template=feedback.yml). Every piece of feedback gets an answer, and changes that come from it are credited in the release notes.

Cracks we found and sealed: [LEDGER.md](LEDGER.md).

## Contribute

- Pick up the next piece of work from the [Menu](pantry/MENU.md): each item has a Done-when anyone can check, and the research behind it lives in [`pantry/`](pantry/README.md).
- New here? Start with the [good first issues](https://github.com/HermeticOrmus/LibreDevOps-Claude-Code/contribute).
- Use the forms: [feedback](https://github.com/HermeticOrmus/LibreDevOps-Claude-Code/issues/new?template=feedback.yml), [routing miss](https://github.com/HermeticOrmus/LibreDevOps-Claude-Code/issues/new?template=routing-miss.yml) when Claude picks the wrong plugin, and [plugin proposal](https://github.com/HermeticOrmus/LibreDevOps-Claude-Code/issues/new?template=plugin-proposal.yml).
- Questions and show-and-tell go in [Discussions](https://github.com/HermeticOrmus/LibreDevOps-Claude-Code/discussions).

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
- [code-comprehension-skills](https://github.com/HermeticOrmus/code-comprehension-skills) — Understand an unfamiliar codebase fast
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
