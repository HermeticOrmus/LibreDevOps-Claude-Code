# Troubleshooting

## Plugins not loaded
```bash
ls ~/.claude/plugins/ | grep -c '^libre-devops-'
```
Should print 25. Re-run `./setup.sh` + restart Claude Code if not.

## Common k8s scenarios

The `/k8s` agent diagnoses:
- Pod won't schedule → resource requests vs node capacity, anti-affinity, taints
- OOMKilled → memory limit too low or leak
- CrashLoopBackOff → probe firing too early, missing config, container exit
- ImagePullBackOff → registry auth or wrong tag
- Slow rollout → maxUnavailable too tight or probe slow

See plugin SKILL.md for the full debug catalog.
