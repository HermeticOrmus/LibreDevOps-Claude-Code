# Menu: LibreDevOps-Claude-Code

Queue: 2026-09-30-pantry-queue.md
Counts: open 7, in flight 0, shipped 0, parked 0, dropped 0, needs fixing 0

## Steer

- none

## Up next

**destroy-guard**: Ask before destructive shell commands (`destroy-guard`) (queue #1, high, repo, since 2026-09-30)

- Done when: `plugins/libre-devops-hooks/hooks/hooks.json` has a PreToolUse entry with matcher `Bash`; its script, fed `{"tool_name":"Bash","tool_input":{"command":"terraform destroy -auto-approve"},"cwd":"."}` on stdin, prints JSON with `hookSpecificOutput.permissionDecision` set to `ask`, and does the same for `tofu destroy`, `terraform apply -auto-approve`, `kubectl delete` and `helm uninstall`; fed `terraform plan` it prints nothing; `claude plugin validate plugins/libre-devops-hooks` passes; the plugin README table describes the new hook
- Verify on: repo
- Evidence: X: Al_Grigor, Ed_Forson, milesdeutscher; map: Confirmation before destructive shell commands (Us N)
- Issue: none yet (promote after merge)
- Order: destroy-guard, hook-tests, logs, live-state-docs, policy-as-code, k8s-evals, codex-marketplace
- Tie: destroy-guard over hook-tests, logs, by key order (jev off)

## Atoms

| Key | Title | State | Confidence | Class | Since | Queue # | Issue | Because |
|-----|-------|-------|------------|-------|-------|---------|-------|---------|
| codex-marketplace | Codex marketplace manifest (`codex-marketplace`) | open | low | repo | 2026-09-30 | 7 | - | - |
| destroy-guard | Ask before destructive shell commands (`destroy-guard`) | open | high | repo | 2026-09-30 | 1 | - | - |
| hook-tests | Fixture tests for the hook scripts (`hook-tests`) | open | high | repo | 2026-09-30 | 2 | - | - |
| k8s-evals | Eval suite for kubernetes-operations manifests (`k8s-evals`) | open | medium | eval | 2026-09-30 | 6 | - | - |
| live-state-docs | Document read-only MCP pairing for live state (`live-state-docs`) | open | medium | repo | 2026-09-30 | 4 | - | - |
| logs | Add a `/logs` command to log-management | open | high | repo | 2026-09-30 | 3 | - | - |
| policy-as-code | New plugin `policy-as-code` for OPA, Conftest and Kyverno | open | medium | repo | 2026-09-30 | 5 | - | - |

## Retired

| Key | Title | State | Since | Issue | Because |
|-----|-------|-------|-------|-------|---------|
| none | | | | | |

## Notes

- none
