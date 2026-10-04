# Contributing

PRs welcome for plugin depth, cloud-provider variations, real-world ops case studies.

## Ways to contribute

- **Take a Menu item.** [`pantry/MENU.md`](pantry/MENU.md) is the ordered list of work, researched and cited in [`pantry/`](pantry/README.md), with one item marked up next and a Done-when anyone can check. Open items are also on the [`menu` issues](https://github.com/HermeticOrmus/LibreDevOps-Claude-Code/issues?q=is%3Aopen+label%3Amenu) and the [good first issues](https://github.com/HermeticOrmus/LibreDevOps-Claude-Code/contribute). Claim one by commenting on its issue, then open a pull request that says `Closes #N`.
- **Report or fix a routing miss.** When Claude picks the wrong agent, command or skill, or none, [open a routing miss](https://github.com/HermeticOrmus/LibreDevOps-Claude-Code/issues/new?template=routing-miss.yml). The fix is usually a sharper `description` in the frontmatter of the file that should have run, which makes it a good first pull request.
- **Propose or build a plugin.** [Open a plugin proposal](https://github.com/HermeticOrmus/LibreDevOps-Claude-Code/issues/new?template=plugin-proposal.yml) with the job it does and a Done-when. To build one, follow the layout every plugin here uses:
  - `plugins/<name>/.claude-plugin/plugin.json` with `name`, `version`, `description`, `author`, `homepage`, `repository`, `license` and `keywords`
  - `plugins/<name>/agents/<agent>.md` with `name`, `description` (start with "Use this agent when...") and `model: inherit` frontmatter
  - `plugins/<name>/commands/<command>.md` with `description` and `argument-hint` frontmatter
  - `plugins/<name>/skills/<skill>/SKILL.md` with `name` and `description` frontmatter that says what it provides and when to use it
  - `plugins/<name>/README.md`, and an entry in [`.claude-plugin/marketplace.json`](.claude-plugin/marketplace.json) with `name`, `source`, `description` and `version`
  - A row in the README plugin tables
- **Translate.** The pack is English only today. If you want to translate the README, QUICK_START or a learning path, open a [feedback issue](https://github.com/HermeticOrmus/LibreDevOps-Claude-Code/issues/new?template=feedback.yml) first so we can agree on how the translation stays in sync.
- **Share what you built.** Post the pipeline, cluster setup or runbook you made with these plugins in [Discussions, Show and tell](https://github.com/HermeticOrmus/LibreDevOps-Claude-Code/discussions/categories/show-and-tell).

### Test your change locally

Load a plugin from your checkout for one session, without installing it, and check what it loaded:

```bash
claude --plugin-dir ./plugins/<name>
claude --plugin-dir ./plugins/<name> plugin details <name>
```

Validate the marketplace and the plugin you changed:

```bash
claude plugin validate .
claude plugin validate plugins/<name>
```

Install into a clean config, the way a new user would:

```bash
export CLAUDE_CONFIG_DIR=$(mktemp -d)
claude plugin marketplace add ./
claude plugin install <name>@libre-devops
claude plugin details <name>@libre-devops
```

`claude plugin details` lists the agents, skills (commands show up here too) and hooks the plugin loaded. To check a hook script, feed it the JSON Claude Code sends:

```bash
echo '{"tool_name":"Edit","tool_input":{"file_path":".env"},"cwd":"."}' | bash plugins/libre-devops-hooks/hooks/pre-tool-use.sh
```

CI (`.github/workflows/check.yml`, running `bash scripts/check.sh`) runs the same validation and clean-config install for every plugin on every pull request. A first-time contributor's CI run waits until a maintainer approves it.

## Welcome
- Plugin deepening (see CHANGELOG maturity matrix)
- Per-cloud variations (EKS vs GKE vs AKS quirks)
- Real incident case studies (anonymized)
- Tooling deep-dives per CI/CD platform

## Not accepted
- Vendor-specific patterns without an open alternative
- AI-generated content not verified against real clusters

## Branch / PR
- `feat/`, `fix/`, `deepen/<plugin>`, `casestudy/<slug>`
- Commit format: `type(scope): description`
- PR template: Why / What / How to verify / Notes

## License
MIT, no CLA.
