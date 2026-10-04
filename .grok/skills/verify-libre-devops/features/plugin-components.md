# Plugin components load

Each installed plugin brings its skills, commands, agents and hooks into the CLI. A plugin that installs but fails to load a component is broken for the user even when its install exits 0.

## Sub-features

- `components-claude` lists a plugin's skills, agents, hooks and MCP servers in Claude Code.
- `components-grok` lists a plugin's skill, command and agent folders in Grok Build.
- `load-errors` reports any plugin that Claude Code could not load.

## How to get to it (user POV)

- Inside Claude Code, `/plugin` shows each installed plugin and its components; from a terminal, `claude plugin details kubernetes-operations@libre-devops`.
- From a terminal, `grok plugin details kubernetes-operations`.

## Driving it with control-libre-devops

Preconditions:

- `.grok/skills/verify-libre-devops/bin/control-libre-devops doctor` reports `worth_driving: true`.

- **Install and inventory.** Run `.grok/skills/verify-libre-devops/bin/control-libre-devops run --only kubernetes-operations`. `evidence/details-claude-kubernetes-operations.txt` has a `Component inventory` block and `evidence/details-grok-kubernetes-operations.txt` has a `components:` line.
- **No load errors.** In the printed `result.json`, `claude.load_errors` is empty and `ok` is true.
- **A changed component.** For a change that adds or renames a skill, command or agent, run `.grok/skills/verify-libre-devops/bin/control-libre-devops install --only <plugin>` and then `.grok/skills/verify-libre-devops/bin/control-libre-devops details <plugin>`. The new name appears in the Claude Code inventory, and the Grok counts match the folders in the plugin.
- **Proof.** Keep the two details files and `result.json`, then run `.grok/skills/verify-libre-devops/bin/control-libre-devops cleanup` after an `install`.

## Gotchas

- Claude Code lists a plugin's commands with its skills in `details`; there is no separate commands line.
- Grok's `details` counts component folders, not individual skills.
- An install that exits 0 can still carry load errors. Read `load_errors`, not only the install log.
