# Kintsugi ledger: LibreDevOps-Claude-Code

Kintsugi mends broken pottery with gold, so the repair is the part you see. Here it means every crack we found in LibreDevOps is written down with its evidence and the seal that closed it, so you can check the gold yourself.

A row is `hallmarked` when its seal shipped in a release that was verified by installing from GitHub into a clean config. Grades: `hairline` is copy or cosmetic, `fracture` is wrong behavior with a workaround, `break` means it did not work or broke a safety promise. IDs are never reused.

| ID | Crack | Evidence | Grade | Tracker | Seal | State |
|----|-------|----------|-------|---------|------|-------|
| K-01 | Nothing installed: the repo had no marketplace or plugin manifests, and the old `setup.sh` copied folders into `~/.claude/plugins`, which Claude Code does not load as plugins. | [PR #2][pr2], [CHANGELOG 1.0.0 L5][a5], [L10][a10], [L20][a20] | break | filed #1 | `marketplace.json` plus a `plugin.json` per plugin; `setup.sh` installs through `claude plugin`; large | hallmarked |
| K-02 | Agents and commands lived in `agents/<name>/AGENT.md` and `commands/<name>/COMMAND.md`, a layout Claude Code does not load. | [PR #2][pr2], [CHANGELOG 1.0.0 L19][a19] | break | filed #1 | Moved with `git mv` to `agents/<name>.md` and `commands/<name>.md`, content unchanged; medium | hallmarked |
| K-03 | 74 of the 75 agent, command, and skill files had no frontmatter, so Claude Code could not route to them. | [PR #2][pr2], [CHANGELOG 1.0.0 L11][a11] | break | filed #1 | A routing description on every file, and an `argument-hint` on every command; large | hallmarked |
| K-04 | `kubernetes-operations` shipped two `k8s-engineer` agents and two `/k8s` commands. | [PR #2][pr2], [CHANGELOG 1.0.0 L26][a26] | fracture | filed #1 | Each pair merged into one file that keeps every unique section; medium | hallmarked |
| K-05 | `k8s-engineer` was pinned to `sonnet` instead of the session's model. | [PR #2][pr2], [CHANGELOG 1.0.0 L21][a21] | fracture | filed #1 | Every agent uses `model: inherit`; small | hallmarked |
| K-06 | The hooks never ran: the old `setup.sh` did not register them. | [PR #2][pr2], [CHANGELOG 1.0.0 L27][a27] | break | filed #1 | The `libre-devops-hooks` plugin wires them through `hooks/hooks.json` and `${CLAUDE_PLUGIN_ROOT}`; medium | hallmarked |
| K-07 | The hook output used fields Claude Code does not read. | [PR #2][pr2], [CHANGELOG 1.0.0 L27][a27] | break | filed #1 | Findings go back as `hookSpecificOutput.additionalContext`; small | hallmarked |
| K-08 | The hook scripts wrote log files. | [PR #2][pr2], [CHANGELOG 1.0.0 L22][a22] | fracture | filed #1 | The scripts read stdin JSON with `jq` and write nothing to disk; small | hallmarked |
| K-09 | The Compose exposed-port check did not read list entries. | [PR #2][pr2], [CHANGELOG 1.0.0 L27][a27] | fracture | filed #1 | The check reads each `ports` list entry; small | hallmarked |
| K-10 | The CI secret-echo check did not match `${{ secrets.X }}`. | [PR #2][pr2], [CHANGELOG 1.0.0 L27][a27] | fracture | filed #1 | The pattern matches the `${{ secrets.X }}` form; small | hallmarked |
| K-11 | The missing-backend warning was raised inside Terraform modules. | [PR #2][pr2], [CHANGELOG 1.0.0 L27][a27] | fracture | filed #1 | No missing-backend warning inside a module; small | hallmarked |
| K-12 | The `.gitignore` check ran for edits to files that are not infrastructure files. | [PR #2][pr2] (hooks plugin, Fixed) | fracture | filed #1 | The `.gitignore` check runs only for infrastructure files; small | hallmarked |
| K-13 | The hook scripts used `mapfile`, which bash 3.2 (the macOS default) does not have. | [PR #2][pr2] (hooks plugin, Fixed) | fracture | filed #1 | No `mapfile`; the scripts run under bash 3.2; small | hallmarked |
| K-14 | A `jq` expression in the `/k8s` debug snippets was invalid. | [PR #2][pr2], [CHANGELOG 1.0.0 L28][a28] | fracture | filed #1 | The expression is fixed; small | hallmarked |
| K-15 | QUICK_START and TROUBLESHOOTING described the old folder copy. | [PR #2][pr2], [CHANGELOG 1.0.0 L29][a29] | hairline | filed #1 | Both describe the plugin-system install; small | hallmarked |
| K-16 | The README Domain column listed things the plugins do not cover, such as Swarm, GCR, ACR, Cloud Functions, and Consul, and its counts did not match the manifests. | [PR #2][pr2], [CHANGELOG 1.0.0 L23][a23] | hairline | filed #1 | The tables name each plugin's agent and command and what it covers; every count matches the manifests; small | hallmarked |
| K-17 | `./setup.sh --help` printed the first line of code after the usage text. | [PR #4][pr4], [CHANGELOG 1.0.1 L7][b7] | hairline | filed #3 | Usage prints the header comment and stops at the first line of code; small | hallmarked |
| K-18 | `./setup.sh --uninstall` reported a failure for every plugin that was never installed. | [PR #4][pr4], [CHANGELOG 1.0.1 L8][b8] | fracture | filed #3 | Uninstall removes only the plugins `claude plugin list` shows; small | hallmarked |
| K-19 | The log-management plugin README names a `/logs` command, but the plugin ships no command. | `plugins/log-management/README.md:8`; `plugins/log-management/` has only `agents/` and `skills/`; [pantry queue][queue] atom 3 | hairline | Menu atom `logs` | Add `commands/logs.md` with `description` and `argument-hint`, and name `/logs` in the README row; small | open |
| K-20 | The `libre-devops-hooks` plugin has not run inside a live Grok Build session, so its runtime behavior there is unverified. | `grok plugin validate plugins/libre-devops-hooks` passes and lists hooks (grok 1.0.44). *Inferred*: Grok's hooks guide shows a camelCase stdin envelope (`toolName`, `toolInput`, Grok tool names); fed that envelope for a `.env` edit, `pre-tool-use.sh` prints nothing, while the Claude Code envelope gets `ask`. | hairline | new | Read both envelopes (`.tool_name // .toolName`, `.tool_input // .toolInput`) and Grok tool names, then record each hook's output in a live Grok session; small | open |

[pr2]: https://github.com/HermeticOrmus/LibreDevOps-Claude-Code/pull/2
[pr4]: https://github.com/HermeticOrmus/LibreDevOps-Claude-Code/pull/4
[a5]: https://github.com/HermeticOrmus/LibreDevOps-Claude-Code/blob/4b02f685d0bb2addbce0c21998577fd3b6f270ff/CHANGELOG.md?plain=1#L5
[a10]: https://github.com/HermeticOrmus/LibreDevOps-Claude-Code/blob/4b02f685d0bb2addbce0c21998577fd3b6f270ff/CHANGELOG.md?plain=1#L10
[a11]: https://github.com/HermeticOrmus/LibreDevOps-Claude-Code/blob/4b02f685d0bb2addbce0c21998577fd3b6f270ff/CHANGELOG.md?plain=1#L11
[a19]: https://github.com/HermeticOrmus/LibreDevOps-Claude-Code/blob/4b02f685d0bb2addbce0c21998577fd3b6f270ff/CHANGELOG.md?plain=1#L19
[a20]: https://github.com/HermeticOrmus/LibreDevOps-Claude-Code/blob/4b02f685d0bb2addbce0c21998577fd3b6f270ff/CHANGELOG.md?plain=1#L20
[a21]: https://github.com/HermeticOrmus/LibreDevOps-Claude-Code/blob/4b02f685d0bb2addbce0c21998577fd3b6f270ff/CHANGELOG.md?plain=1#L21
[a22]: https://github.com/HermeticOrmus/LibreDevOps-Claude-Code/blob/4b02f685d0bb2addbce0c21998577fd3b6f270ff/CHANGELOG.md?plain=1#L22
[a23]: https://github.com/HermeticOrmus/LibreDevOps-Claude-Code/blob/4b02f685d0bb2addbce0c21998577fd3b6f270ff/CHANGELOG.md?plain=1#L23
[a26]: https://github.com/HermeticOrmus/LibreDevOps-Claude-Code/blob/4b02f685d0bb2addbce0c21998577fd3b6f270ff/CHANGELOG.md?plain=1#L26
[a27]: https://github.com/HermeticOrmus/LibreDevOps-Claude-Code/blob/4b02f685d0bb2addbce0c21998577fd3b6f270ff/CHANGELOG.md?plain=1#L27
[a28]: https://github.com/HermeticOrmus/LibreDevOps-Claude-Code/blob/4b02f685d0bb2addbce0c21998577fd3b6f270ff/CHANGELOG.md?plain=1#L28
[a29]: https://github.com/HermeticOrmus/LibreDevOps-Claude-Code/blob/4b02f685d0bb2addbce0c21998577fd3b6f270ff/CHANGELOG.md?plain=1#L29
[b7]: https://github.com/HermeticOrmus/LibreDevOps-Claude-Code/blob/a810d2fa0d4f1191a79246c0443f0166129d97dc/CHANGELOG.md?plain=1#L7
[b8]: https://github.com/HermeticOrmus/LibreDevOps-Claude-Code/blob/a810d2fa0d4f1191a79246c0443f0166129d97dc/CHANGELOG.md?plain=1#L8
[queue]: pantry/2026-09-30-pantry-queue.md

<p align="center"><img src="https://brand.ormus.solutions/assets/marks/kintsugi-mark.svg" alt="Kintsugi mark" width="48" /></p>
