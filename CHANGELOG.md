# Changelog

## [Unreleased]

### Added

- A public pantry (`pantry/`) with a cited competitor map, X mine, people mine and pantry queue, and a Menu (`pantry/MENU.md`) generated from the queue that names one up-next item with a Done-when anyone can check.
- Two issue forms: routing miss, for when Claude picks the wrong agent, command or skill, and plugin proposal.
- A Ways to contribute section in CONTRIBUTING.md with the local test loop, and a Contribute section in the README.
- Grok Build support: `.grok-plugin/marketplace.json`, generated from the Claude Code manifest by `scripts/sync-grok-manifest.py`, so `grok plugin marketplace add HermeticOrmus/LibreDevOps-Claude-Code` lists all 26 plugins. CI fails when the file drifts, validates every plugin with `grok plugin validate`, and installs them all into a clean Grok home. README and QUICK_START show the Grok Build install.
- `setup.sh --grok` installs through the Grok Build CLI instead of Claude Code, with the same `--only`, `--list`, and `--uninstall`.
- `LEDGER.md`, the kintsugi ledger: every crack the 1.0 releases found and sealed, with evidence, and the cracks still open.

## [1.0.1] - 2026-09-30

### Fixed

- `./setup.sh --help` printed the first line of code after the usage text; it now prints only the usage.
- `./setup.sh --uninstall` reported a failure for every plugin that was never installed; it now skips those and removes only what is installed.

## [1.0.0] - 2026-09-30

The first release that installs as a Claude Code plugin marketplace. The old `setup.sh` copied plugin folders into `~/.claude/plugins`, which Claude Code does not load as plugins, so for most people this is the first version where the agents, commands, and skills actually show up.

Upgrading from 0.2.0: delete any `~/.claude/plugins/libre-devops-*` folders the old installer created, then run `./setup.sh` from an updated clone, or use `/plugin marketplace add HermeticOrmus/LibreDevOps-Claude-Code` and `/plugin install <plugin>@libre-devops`.

### Added
- `.claude-plugin/marketplace.json` (marketplace `libre-devops`) and a `plugin.json` for every plugin, each with a one-sentence description and domain keywords.
- Routing frontmatter for all 25 agents, 24 commands, and 26 skills: agents say when to use them, skills say what they provide and when to reach for them, and commands carry an `argument-hint` that lists their actions.
- `libre-devops-hooks`, an optional plugin with three hooks: one line of project context at session start in infrastructure repos, a confirmation before edits to Terraform state, credential, `.env`, key, and secrets files, and post-edit checks for Terraform, Kubernetes, Dockerfiles, CI/CD, Compose, Ansible, and leaked secrets.
- `setup.sh --list`, `--scope`, and `--uninstall`.
- A CI workflow that validates the marketplace and every plugin, then installs them all into a clean config.
- A feedback issue form and a Feedback section in the README.
- An operations reference in `/k8s` for deploy, scale, debug, and upgrade.

### Changed
- Agents and commands moved from `agents/<name>/AGENT.md` and `commands/<name>/COMMAND.md` to `agents/<name>.md` and `commands/<name>.md`, the layout Claude Code loads. Their content is unchanged apart from the new frontmatter.
- `setup.sh` registers the checkout as a marketplace and installs through `claude plugin install`. `--plugins-dir` is still accepted but no longer used. A full run also installs `libre-devops-hooks`; pass `--only` to leave it out.
- Agents use `model: inherit`, so they run on the model your session uses. `k8s-engineer` was pinned to `sonnet`.
- The hook scripts moved from `hooks/` to `plugins/libre-devops-hooks/hooks/`. They read hook input as JSON on stdin with `jq` and no longer write log files.
- The README plugin tables now name each plugin's agent and command and describe what each plugin actually covers, and every count matches the manifests.

### Fixed
- `kubernetes-operations` shipped two `k8s-engineer` agents and two `/k8s` commands. Each pair is now one file that keeps every unique section: rollout details, HPA behavior and KEDA, Helm chart structure, kubectl debugging, the decision guide, and the operations reference.
- The hooks never ran: the old `setup.sh` did not register them, and their output used fields Claude Code does not read. The Compose exposed-port check, the CI secret-echo check, and the missing-backend check (no longer raised inside Terraform modules) now work as intended.
- An invalid `jq` expression in the `/k8s` debug snippets.
- QUICK_START and TROUBLESHOOTING describe the plugin-system install instead of the old folder copy.

## [0.2.0] — 2026-05-23

- LibreUIUX doc chrome applied
- **kubernetes-operations** plugin promoted to depth-complete
- 3-tier learning paths added
- 25 plugins total: 1 depth-complete, 24 shell-improved

### v0.3-v0.5 priorities
- terraform-patterns, github-actions, monitoring-observability (v0.3)
- aws-infrastructure, azure-infrastructure, gcp-infrastructure (v0.4)
- secret-management, incident-management, cost-optimization (v0.5)

## [0.1.0] — 2026-03-01
Initial release. 25 plugin shells.
