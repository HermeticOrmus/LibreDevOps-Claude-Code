# /ansible

Generate playbooks, scaffold roles, manage Vault secrets, and run Molecule tests for Ansible automation.

## Usage

```
/ansible playbook|role|vault|test [options]
```

## Actions

### `playbook`
Generate a production-ready playbook with handlers, error handling, and rolling deploy support.

```yaml
# Example: /ansible playbook --name deploy-webapp --hosts webservers
---
- name: Deploy webapp to webservers
  hosts: webservers
  become: true
  gather_facts: true
  serial: "25%"
  max_fail_percentage: 10
  vars:
    app_version: "{{ app_version | mandatory }}"
    app_port: 8080

  pre_tasks:
    - name: Assert required variables
      assert:
        that:
          - app_version is defined
          - app_version | length > 0

  roles:
    - common
    - webapp

  handlers:
    - name: restart webapp
      service:
        name: webapp
        state: restarted
```

### `role`
Scaffold a role with full directory layout and Molecule default scenario.

```bash
# Scaffold role
ansible-galaxy init roles/nginx --offline

# Required meta/main.yml
galaxy_info:
  author: your-name
  description: Manages nginx reverse proxy
  min_ansible_version: "2.14"
  platforms:
    - name: Ubuntu
      versions: ["22.04", "24.04"]
dependencies:
  - role: common
```

Role tasks/main.yml pattern:
```yaml
---
# tasks/main.yml
- name: Install nginx
  ansible.builtin.apt:
    name: nginx
    state: present
    update_cache: true
  notify: reload nginx

- name: Deploy nginx configuration
  ansible.builtin.template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
    owner: root
    group: root
    mode: "0644"
    validate: nginx -t -c %s
  notify: reload nginx

- name: Ensure nginx is started and enabled
  ansible.builtin.service:
    name: nginx
    state: started
    enabled: true
```

### `vault`
Encrypt secrets with Ansible Vault.

```bash
# Encrypt a string value
ansible-vault encrypt_string 'db_password_here' --name 'vault_db_password'

# Encrypt entire secrets file
ansible-vault encrypt group_vars/prod/vault.yml

# Edit encrypted file
ansible-vault edit group_vars/prod/vault.yml

# Rotate vault password
ansible-vault rekey group_vars/prod/vault.yml

# Run with vault password file (for CI)
ansible-playbook site.yml --vault-password-file ~/.vault_pass

# Vault ID for multi-environment secrets
ansible-vault encrypt_string 'value' \
  --vault-id prod@prompt \
  --name 'vault_api_key'
```

### `test`
Run Molecule tests for role validation.

```bash
# Full test lifecycle (create, converge, idempotency check, verify, destroy)
molecule test

# Iterative development (create + converge only, keep container)
molecule converge

# Run verify only (container must exist from previous converge)
molecule verify

# Test idempotency (run converge twice, assert no changes on second run)
molecule idempotency

# List molecule scenarios
molecule list

# Run specific scenario
molecule test --scenario-name centos
```

```yaml
# molecule/default/molecule.yml
---
dependency:
  name: galaxy
driver:
  name: docker
platforms:
  - name: ubuntu-22
    image: geerlingguy/docker-ubuntu2204-ansible:latest
    pre_build_image: true
provisioner:
  name: ansible
  playbooks:
    converge: converge.yml
verifier:
  name: ansible
```

## Ansible Lint in CI

```yaml
# .github/workflows/ansible-lint.yml
- name: Run ansible-lint
  uses: ansible/ansible-lint-action@v6
  with:
    args: site.yml roles/

# .ansible-lint (project config)
warn_list:
  - yaml[line-length]
skip_list:
  - no-changed-when  # Allow in specific cases with justification
```

## Common Flags Reference

```bash
# Syntax check without running
ansible-playbook site.yml --syntax-check

# Dry run with diff output
ansible-playbook site.yml --check --diff

# Limit to specific hosts or groups
ansible-playbook site.yml --limit webservers
ansible-playbook site.yml --limit "web01,web02"

# Run only tagged tasks
ansible-playbook site.yml --tags deploy
ansible-playbook site.yml --skip-tags notify

# Verbose output (1-4 levels)
ansible-playbook site.yml -v      # Task results
ansible-playbook site.yml -vv     # Input/output
ansible-playbook site.yml -vvv    # Connection info
ansible-playbook site.yml -vvvv   # All SSH details

# Override variables
ansible-playbook site.yml -e "app_version=1.2.3 env=prod"

# Step through tasks interactively
ansible-playbook site.yml --step
```
