# Contributor Covenant Code of Conduct

## Our Pledge

We as members, contributors, and leaders pledge to make participation in our community a harassment-free experience for everyone, regardless of age, body size, visible or invisible disability, ethnicity, sex characteristics, gender identity and expression, level of experience, education, socio-economic status, nationality, personal appearance, race, caste, color, religion, or sexual identity and orientation.

We pledge to act and interact in ways that contribute to an open, welcoming, diverse, inclusive, and healthy community.

As an infrastructure-focused community, we additionally pledge to:

- **Share production-tested knowledge** that helps others avoid outages, data loss, and security incidents.
- **Document failure modes honestly** -- post-mortems and lessons learned are among the most valuable contributions.
- **Respect cost implications** -- cloud resources cost real money. Always document cost impact and cleanup procedures.
- **Prioritize safety over speed** -- infrastructure changes affect real systems and real users.

## Our Standards

Examples of behavior that contributes to a positive environment for our community:

* Demonstrating empathy and kindness toward other people
* Being respectful of differing opinions, viewpoints, and experiences
* Giving and gracefully accepting constructive feedback
* Accepting responsibility and apologizing to those affected by our mistakes, and learning from the experience
* Focusing on what is best not just for us as individuals, but for the overall community
* Sharing infrastructure knowledge openly to raise collective operational capability
* Documenting not just what works, but what failed and why

Examples of unacceptable behavior:

* The use of sexualized language or imagery, and sexual attention or advances of any kind
* Trolling, insulting or derogatory comments, and personal or political attacks
* Public or private harassment
* Publishing others' private information, such as a physical or email address, without their explicit permission
* Other conduct which could reasonably be considered inappropriate in a professional setting
* **Sharing real credentials, API keys, or cloud account identifiers** in any contribution
* **Publishing infrastructure configs** that could cause data loss if applied without warning
* **Omitting cost warnings** for configurations that create paid cloud resources
* **Recommending destructive operations** (terraform destroy, kubectl delete namespace) without clear warnings and confirmation steps

## Infrastructure-Specific Standards

### Production Safety

All infrastructure content shared within this community must prioritize production safety:

1. **State management required** -- Terraform configs must include backend configuration. Ansible playbooks must be idempotent.
2. **Secrets must use placeholders** -- Use `${VAR_NAME}`, `<YOUR_API_KEY>`, or environment variable references. Never real credentials.
3. **Destructive operations flagged** -- Any operation that deletes data, removes resources, or modifies production must include explicit warnings.
4. **Cost implications stated** -- Cloud resource configurations must note estimated costs or confirm free-tier eligibility.
5. **Cleanup documented** -- Every resource created must have a documented destruction path.

### Responsible Infrastructure

When sharing infrastructure patterns, deployment strategies, or operational procedures:

- Clearly state the target environment (local, development, staging, production)
- Note any prerequisites (existing infrastructure, IAM permissions, network configuration)
- Include rollback procedures for any change that modifies existing resources
- Test in non-production environments before recommending for production use

## Enforcement Responsibilities

Community leaders are responsible for clarifying and enforcing our standards of acceptable behavior and will take appropriate and fair corrective action in response to any behavior that they deem inappropriate, threatening, offensive, or harmful.

Community leaders have the right and responsibility to remove, edit, or reject comments, commits, code, wiki edits, issues, and other contributions that are not aligned with this Code of Conduct, and will communicate reasons for moderation decisions when appropriate.

## Scope

This Code of Conduct applies within all community spaces, and also applies when an individual is officially representing the community in public spaces.

## Enforcement

Instances of abusive, harassing, or otherwise unacceptable behavior may be reported to the community leaders responsible for enforcement at:

**Email:** hermeticormus@proton.me

**For infrastructure safety violations** (real credentials shared, destructive operations without warnings):
- The content will be removed immediately without prior warning
- If real credentials were exposed, affected parties will be notified
- The contributor will be contacted to rotate any compromised credentials

All complaints will be reviewed and investigated promptly and fairly.

## Enforcement Guidelines

Community leaders will follow these Community Impact Guidelines in determining the consequences for any action they deem in violation of this Code of Conduct:

### 1. Correction

**Community Impact:** Use of inappropriate language or other behavior deemed unprofessional or unwelcome in the community.

**Consequence:** A private, written warning from community leaders, providing clarity around the nature of the violation and an explanation of why the behavior was inappropriate.

### 2. Warning

**Community Impact:** A violation through a single incident or series of actions.

**Consequence:** A warning with consequences for continued behavior. No interaction with the people involved, including unsolicited interaction with those enforcing the Code of Conduct, for a specified period of time.

### 3. Temporary Ban

**Community Impact:** A serious violation of community standards, including sustained inappropriate behavior or infrastructure safety violations.

**Consequence:** A temporary ban from any sort of interaction or public communication with the community for a specified period of time.

### 4. Permanent Ban

**Community Impact:** Demonstrating a pattern of violation of community standards, including sustained inappropriate behavior, harassment, or repeated infrastructure safety violations.

**Consequence:** A permanent ban from any sort of public interaction within the community.

## Attribution

This Code of Conduct is adapted from the [Contributor Covenant][homepage], version 2.1, available at [https://www.contributor-covenant.org/version/2/1/code_of_conduct.html][v2.1].

Community Impact Guidelines were inspired by [Mozilla's code of conduct enforcement ladder][Mozilla CoC].

Infrastructure-specific standards were developed by the LibreDevOps community to reflect the unique responsibilities of infrastructure engineering education.

[homepage]: https://www.contributor-covenant.org
[v2.1]: https://www.contributor-covenant.org/version/2/1/code_of_conduct.html
[Mozilla CoC]: https://github.com/mozilla/diversity
