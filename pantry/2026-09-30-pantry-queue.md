# Pantry queue: LibreDevOps-Claude-Code

## How this fills

1. Read the latest competitor map, X mine and people mine.
2. Propose 5 to 8 Goal atoms that answer their themes. The Menu needs at least 3.
3. Each atom needs a Done predicate someone else can check on this repo, a surface, the evidence rows it answers, and a confidence (high, medium or low).
4. Save as `YYYY-MM-DD-pantry-queue.md`; the Menu reads the newest one.
5. Retire an atom only with a bullet under "Explicitly not stocked" of the form `<Title>: shipped, PR #N` or `<Title>: parked, <reason>`.

Sources for this run: [competitor map](2026-09-30-competitor-map.md), [X mine](2026-09-30-x-mine.md), [people mine](2026-09-30-people-mine.md) (no outside voices yet).

## Atoms

| # | Title | Done predicate | Surface | Evidence | Confidence |
|---|-------|----------------|---------|----------|------------|
| 1 | Ask before destructive shell commands (`destroy-guard`) | `plugins/libre-devops-hooks/hooks/hooks.json` has a PreToolUse entry with matcher `Bash`; its script, fed `{"tool_name":"Bash","tool_input":{"command":"terraform destroy -auto-approve"},"cwd":"."}` on stdin, prints JSON with `hookSpecificOutput.permissionDecision` set to `ask`, and does the same for `tofu destroy`, `terraform apply -auto-approve`, `kubectl delete` and `helm uninstall`; fed `terraform plan` it prints nothing; `claude plugin validate plugins/libre-devops-hooks` passes; the plugin README table describes the new hook | repo | X: Al_Grigor, Ed_Forson, milesdeutscher; map: Confirmation before destructive shell commands (Us N) | high |
| 2 | Fixture tests for the hook scripts (`hook-tests`) | `tests/hooks/run.sh` feeds fixture hook JSON to `session-start.sh`, `pre-tool-use.sh` and `post-tool-use.sh` and compares each output with an expected file, with one fixture per check family (Terraform, Kubernetes, Dockerfile, CI/CD, Compose, Ansible, a secret-file edit, a clean file that must print nothing); `bash tests/hooks/run.sh` exits 0; `.github/workflows/validate.yml` runs it on every pull request | repo | map: Tests or evals of the pack itself (Us P, wsh Y, tfs P); map: Post-edit infrastructure checks in the editor (Us Y, unproven by tests) | high |
| 3 | Add a `/logs` command to log-management | `plugins/log-management/commands/logs.md` exists with `description` and `argument-hint` frontmatter; `claude plugin validate plugins/log-management` passes; after a clean-config install, `claude plugin details log-management@libre-devops` lists `logs` under Skills; the README log-management row names `/logs` instead of none | repo | map: Observability and SLOs (Us: `log-management` ships no command, every other domain plugin does) | high |
| 4 | Document read-only MCP pairing for live state (`live-state-docs`) | README gains a `## Live state with MCP` section with `claude mcp add` commands, checked against `claude mcp add --help`, for `hashicorp/terraform-mcp-server` and `containers/kubernetes-mcp-server` with its `read_only` option on, and names the LibreDevOps plugins each server pairs with | repo | map: Live cluster or cloud state (Us N; gcd, k8g, hgp Y; rows awslabs/mcp, containers/kubernetes-mcp-server, hashicorp/terraform-mcp-server); X: antonbabenko 2026-01-18, DataChaz | medium |
| 5 | New plugin `policy-as-code` for OPA, Conftest and Kyverno | `claude plugin validate plugins/policy-as-code` passes; after a clean-config install, `claude plugin details policy-as-code@libre-devops` lists one agent and a command and a skill under Skills; the skill has a Rego policy with the `conftest test` command that runs it and a Kyverno ClusterPolicy example; the plugin is listed in `.claude-plugin/marketplace.json` and in the README plugin tables | repo | map: Policy as code (Us P; hcs Y; tfs Y) | medium |
| 6 | Eval suite for kubernetes-operations manifests (`k8s-evals`) | `plugins/kubernetes-operations/evals/` holds cases that `claude plugin eval plugins/kubernetes-operations` loads and scores, with graders that check a generated Deployment for resource requests and limits, liveness and readiness probes, a non-root securityContext, no wildcard RBAC and a current apiVersion | repo | X: KubeBuilders (KubeShark); map: Tests or evals of the pack itself (Us P, wsh Y) | medium |
| 7 | Codex marketplace manifest (`codex-marketplace`) | `.agents/plugins/marketplace.json` lists the same 26 plugin names as `.claude-plugin/marketplace.json`, every plugin folder has `.codex-plugin/plugin.json`, the README documents the Codex install, and a CI step fails when the two manifests list different plugin names | repo | map: Installs in other agents (Us N; wsh Y; hcs Y, which ships `.agents/plugins/marketplace.json`) | low |

## Explicitly not stocked (and why)

- A Terraform plan review mode: `/terraform plan` already shows `terraform show -json` filtered to deletes; the `destroy-guard` atom covers the X complaints about agents running destructive commands.
- A live-cluster MCP server of our own: k8sgpt, HolmesGPT, awslabs/mcp and containers/kubernetes-mcp-server already do this; the `live-state-docs` atom pairs with them instead.
- Cursor rules export: the map shows Cursor coverage in this domain is thin (one Docker rule in awesome-cursorrules); revisit after the Codex manifest lands.
