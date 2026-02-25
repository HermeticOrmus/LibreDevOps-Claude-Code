## Summary

<!-- Describe what this PR does in 2-3 sentences. Focus on the "why" not the "what". -->

## Type of Change

- [ ] New plugin (infrastructure skill, agent, or command)
- [ ] Enhancement to existing plugin
- [ ] New learning content (beginner/intermediate/advanced)
- [ ] Infrastructure pattern or template
- [ ] CI/CD pipeline configuration
- [ ] Hook or automation
- [ ] Bug fix
- [ ] Documentation update

## Infrastructure Review Checklist

- [ ] **No hardcoded secrets** -- Uses environment variables, secret managers, or placeholders
- [ ] **State management included** -- Backend configuration, locking, recovery procedures documented
- [ ] **Idempotent** -- Safe to apply multiple times without side effects
- [ ] **Secrets management documented** -- How secrets are injected, rotated, and accessed
- [ ] **Cost implications stated** -- Free tier, estimated monthly cost, or "local only"
- [ ] **Cleanup instructions included** -- How to destroy/remove created resources
- [ ] **Failure modes documented** -- What can go wrong and how to recover
- [ ] **Monitoring considerations** -- What to monitor and alert on

## Content Checklist

- [ ] Tested in a real environment (document which below)
- [ ] Follows project structure and naming conventions
- [ ] Includes usage examples with expected output
- [ ] Markdown renders correctly
- [ ] Links are valid

## Testing Notes

<!-- Describe how you tested this contribution. Include:
- Environment: local Docker, Minikube, AWS free tier, GCP, etc.
- Tools and versions: Terraform 1.x, kubectl 1.x, Docker 2x.x
- Steps to reproduce / verify the content works
- Cost incurred (if any)
-->

## References

<!-- Link to relevant documentation, standards, or prior art:
- Terraform provider documentation
- Kubernetes API references
- Cloud provider best practices
- Related issues or PRs
-->

## Additional Context

<!-- Any other information reviewers should know. -->
