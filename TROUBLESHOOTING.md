# Troubleshooting

## Plugins not loaded
```bash
claude plugin list | grep -c '@libre-devops'
```
Should print the number of plugins you installed (26 after a full `./setup.sh`). Re-run `./setup.sh` + restart Claude Code if not.

Earlier versions of `setup.sh` copied folders into `~/.claude/plugins/libre-devops-*`, which Claude Code does not load. Those folders can be deleted once the plugins show up in `claude plugin list`.

## Hooks do nothing
The `libre-devops-hooks` plugin needs `jq` on your PATH; without it the hooks exit silently. Check that the plugin is enabled with `claude plugin list`, then restart Claude Code. The session-start line only appears in projects with infrastructure files (Terraform, Kubernetes manifests, Dockerfiles, CI configs, Ansible, Helm).

## Common k8s scenarios

The `/k8s` agent diagnoses:
- Pod won't schedule → resource requests vs node capacity, anti-affinity, taints
- OOMKilled → memory limit too low or leak
- CrashLoopBackOff → probe firing too early, missing config, container exit
- ImagePullBackOff → registry auth or wrong tag
- Slow rollout → maxUnavailable too tight or probe slow

See plugin SKILL.md for the full debug catalog.
