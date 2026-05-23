<p align="center">
  <img src="https://ormus.solutions/mascot/chain_braces_to_swan.gif" alt="LibreDevOps Claude Code" width="128" style="image-rendering: pixelated;" />
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
