# Contributing to LibreDevOps

Welcome to the infrastructure knowledge commons. This repository maps how to use Claude Code for DevOps, infrastructure as code, CI/CD, and cloud operations. Every contribution raises our shared understanding of AI-assisted infrastructure engineering.

---

## Philosophy

**We build production-grade, not tutorial-grade.**

The gap between "works in a tutorial" and "works in production" is where systems fail. Contributions to LibreDevOps must close that gap -- state management, secrets handling, multi-environment promotion, rollback strategies, monitoring. If your contribution works only in a fresh environment with no existing state, it is incomplete.

**We teach the why, not just the how.**

Every Terraform module, Kubernetes manifest, and CI/CD pipeline encodes decisions. Document those decisions. Why this instance type? Why this replication strategy? Why this deployment order? Infrastructure without reasoning becomes cargo cult operations.

---

## Guiding Principles

1. **Production-readiness required** -- Every config, template, and pattern must handle real-world concerns: state management, secrets, networking, monitoring, and failure modes.
2. **Idempotency is non-negotiable** -- Infrastructure operations must be safe to run multiple times. Document any exceptions explicitly.
3. **No hardcoded secrets** -- Not in examples, not in templates, not in documentation. Use placeholder patterns that make the secret management approach obvious.
4. **Test what you contribute** -- Run `terraform validate`, `docker build`, `kubectl apply --dry-run`, or equivalent before submitting.
5. **Document the blast radius** -- Every infrastructure change has a scope of impact. State it clearly.

---

## Types of Contributions

### Infrastructure Patterns

Production-tested IaC patterns that solve real problems.

**How to contribute:**
1. Test in a real environment (personal cloud account, local cluster, CI pipeline)
2. Document the exact configuration and expected behavior
3. Explain what the tutorial version misses and why this version handles it
4. Include rollback and disaster recovery procedures

**Template:**
```markdown
## [Pattern Name]

### The Problem
[What production scenario does this address?]

### The Pattern
[Exact configuration that works]

### Why This Over the Naive Approach
[What the tutorial version misses]

### State Management
[How state is handled, where it lives, how to recover]

### Failure Modes
[What can go wrong, how to detect, how to recover]

### Monitoring
[What to monitor, what alerts to set]
```

### CI/CD Pipelines

Production-grade pipeline configurations for real deployment workflows.

**Requirements:**
- Must include secrets management (not hardcoded tokens)
- Must include quality gates (tests, linting, security scanning)
- Must include rollback strategy
- Must include deployment approval for production
- Must handle concurrent pipeline runs safely

### Monitoring & Observability

Dashboards, alert rules, SLO definitions, and incident response patterns.

**Requirements:**
- Alert rules must include severity, description, runbook link, and expected false positive rate
- Dashboards must include the "four golden signals": latency, traffic, errors, saturation
- SLO definitions must include error budgets and burn rate alerts

### Plugins, Agents & Commands

New Claude Code extensions for DevOps workflows.

**Requirements:**
- Clear scope definition (what it does and does not do)
- Error handling for infrastructure operations (network timeouts, API rate limits, state locks)
- Usage examples with expected output
- Idempotent by default

### Documentation & Guides

Workflow guides, learning paths, tool comparisons, and reference material.

**Structure:**
- Clear problem statement and target audience
- Progressive difficulty (build understanding step by step)
- Practical exercises with real infrastructure (local Docker, Minikube, free-tier cloud)
- Cost warnings for any cloud resources
- Cleanup instructions

---

## Contribution Process

### 1. Check Existing Work

Search issues and existing content before starting. Infrastructure duplication wastes time and budget.

### 2. Open an Issue (for significant changes)

For new plugins or substantial content, open an issue first to discuss scope. Small fixes and documentation improvements can go directly to PR.

### 3. Fork & Branch

```bash
git clone https://github.com/YOUR-USERNAME/LibreDevOps-Claude-Code.git
cd LibreDevOps-Claude-Code
git checkout -b feature/your-contribution-name
```

**Branch naming:**
- `feature/` -- New content, plugins, or capabilities
- `fix/` -- Bug fixes or corrections
- `docs/` -- Documentation improvements
- `example/` -- New examples or exercises

### 4. Write & Test

Follow the guidelines above. Test everything in a real environment.

### 5. Commit

```
feat(plugin): Add multi-region Terraform state backend pattern

Includes:
- S3 + DynamoDB state backend with cross-region replication
- State locking configuration
- Disaster recovery procedure for state corruption
- Cost estimate for state infrastructure
```

Use conventional commits: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`.

### 6. Submit PR

Open a pull request using the PR template. Include:
- Clear description of what this adds
- Testing environment and methodology
- Cost implications (if any cloud resources involved)
- Cleanup instructions

### 7. Review

Maintainers review for:
- **Production-readiness** -- Does this handle state, secrets, failure modes?
- **Idempotency** -- Can this be applied multiple times safely?
- **Completeness** -- Are monitoring, rollback, and cleanup included?
- **Quality** -- Clear writing, working configurations, proper structure?

---

## Content Guidelines by Difficulty

### Beginner

- Assume no prior infrastructure experience beyond basic terminal usage
- Provide ready-to-use configurations with thorough comments
- Use local tools first (Docker, Minikube, LocalStack) before cloud resources
- Include cost warnings for any cloud operations
- Emphasize "why this matters" for each concept

### Intermediate

- Assume familiarity with Docker, basic Terraform, and one cloud provider
- Introduce multi-environment workflows and state management
- Cover less obvious failure modes (state drift, race conditions, provider API limits)
- Include automation and pipeline patterns
- Connect individual tools to broader platform engineering concepts

### Advanced

- Assume professional infrastructure experience
- Cover multi-cloud, multi-region, and disaster recovery architectures
- Include production-grade monitoring, alerting, and incident response
- Address compliance and governance at scale
- Provide cost optimization strategies for enterprise workloads

---

## Infrastructure Review Checklist

Before submitting, verify:

- [ ] No hardcoded credentials, tokens, API keys, or secrets
- [ ] No real account IDs, project IDs, or organization identifiers
- [ ] State management approach documented
- [ ] Secrets management approach documented
- [ ] Idempotent -- safe to apply multiple times
- [ ] Cleanup instructions included for any created resources
- [ ] Cost implications stated (free tier, estimated monthly cost, or "local only")
- [ ] Tested in a real environment (document which)
- [ ] Monitoring and alerting considerations included

---

## What We Do Not Accept

- **Tutorial-grade configs** -- If it only works on a fresh account with no existing resources, it is not production-ready
- **Hardcoded secrets** -- Not even "example" secrets that look real
- **Untested content** -- Everything must be validated in a real environment
- **Vendor lock-in without alternatives** -- Cloud-specific patterns must note the lock-in and suggest portable alternatives where reasonable
- **Missing state management** -- Terraform without backend config, Ansible without idempotency
- **No cleanup path** -- Infrastructure that creates resources must document how to destroy them

---

## Recognition

Contributors are:
- Listed in commit history and release notes
- Part of the infrastructure knowledge commons
- Building collective operational capability

Your contribution might be one Terraform pattern, one pipeline config, one monitoring dashboard. But someone, somewhere, will avoid a production outage because you documented what you learned.

---

**Share what you build. The infrastructure gets stronger when knowledge flows.**

Thank you for contributing to collective operational excellence.
