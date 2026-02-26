# Ansible Automation Plugin

Ansible playbooks, roles, dynamic inventory, Vault encryption, and Molecule testing for infrastructure automation.

## Components

- **Agent**: `ansible-engineer` -- Designs idempotent playbooks and roles, enforces module-over-shell, manages Vault secrets
- **Command**: `/ansible` -- Generates playbooks, scaffolds roles, runs vault operations, executes Molecule tests
- **Skill**: `ansible-patterns` -- Production patterns: role layout, Jinja2 templates, dynamic inventory, block/rescue handling

## When to Use

- Automating server configuration (OS hardening, package installs, user management)
- Application deployment with rolling updates and health check verification
- Multi-environment config management with group_vars and host_vars
- Secret management with Ansible Vault (inline or file encryption)
- Role testing and idempotency validation with Molecule

## Quick Reference

```bash
# Run a playbook with vault and dry-run check
ansible-playbook site.yml --vault-password-file ~/.vault_pass --check --diff

# Scaffold a new role
ansible-galaxy init roles/redis --offline

# Encrypt a secret for group_vars
ansible-vault encrypt_string 'redis_password' --name 'vault_redis_password'

# Run Molecule full test cycle
molecule test

# Dynamic AWS inventory preview
ansible-inventory -i inventory/aws_ec2.yml --graph

# Run only tagged tasks on specific hosts
ansible-playbook site.yml -i inventory/prod --tags deploy --limit "app*"
```

## Directory Layout for a Real Project

```
ansible-project/
├── ansible.cfg                    # pipelining=True, forks=20, fact caching
├── site.yml                       # Top-level orchestration
├── requirements.yml               # Pinned collections and roles
├── inventory/
│   ├── aws_ec2.yml                # Dynamic AWS EC2 inventory plugin
│   ├── group_vars/
│   │   ├── all/
│   │   │   ├── vars.yml           # Global non-secret vars
│   │   │   └── vault.yml          # Ansible Vault encrypted globals
│   │   ├── webservers/
│   │   │   ├── vars.yml
│   │   │   └── vault.yml
│   │   └── databases/
│   │       ├── vars.yml
│   │       └── vault.yml
│   └── host_vars/
│       └── db-primary.example.com/
│           └── vars.yml           # Host-specific overrides
└── roles/
    ├── common/                    # Base OS config, applied to all hosts
    ├── nginx/                     # Web server configuration
    ├── webapp/                    # Application deployment
    └── postgresql/                # Database setup and config
```

## Key Patterns

**Idempotency**: Every task produces the same result on first and subsequent runs. Use `creates:`, `changed_when:`, and `state:` parameters. Avoid `command`/`shell` except when no module exists.

**Handler-driven restarts**: Services restart via `notify:` handlers, not directly in tasks. Handlers fire once at play end even if notified multiple times -- preventing unnecessary disruption.

**Variable hierarchy**: Defaults in `role/defaults/main.yml` (safe to override), environment specifics in `group_vars/env/vars.yml`, host overrides in `host_vars/`. Secrets always in vault-encrypted files.

**Rolling deployments**: `serial: "25%"` with `max_fail_percentage: 10` deploys to 25% of hosts at a time. Combine with `pre_tasks` load balancer drain and `post_tasks` health checks.

## Related Plugins

- [configuration-management](../configuration-management/) -- Consul/SSM for runtime config, feature flags
- [secret-management](../secret-management/) -- HashiCorp Vault integration beyond Ansible Vault
- [infrastructure-security](../infrastructure-security/) -- CIS benchmark roles, security scanning
- [github-actions](../github-actions/) -- CI pipeline for ansible-lint and Molecule tests
