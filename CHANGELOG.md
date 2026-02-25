# Changelog

All notable changes to LibreDevOps-Claude-Code will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-02-24

### Added

- Initial release with 25 DevOps plugins covering the full infrastructure lifecycle:
  - **Cloud Platforms:** aws-infrastructure, gcp-infrastructure, azure-infrastructure
  - **Containers & Orchestration:** docker-orchestration, kubernetes-operations, container-registry, service-mesh
  - **CI/CD Pipelines:** github-actions, gitlab-ci, jenkins-pipelines, release-management
  - **Infrastructure as Code:** terraform-patterns, ansible-automation, configuration-management, serverless-patterns
  - **Operations:** monitoring-observability, log-management, incident-management, backup-disaster-recovery, cost-optimization, networking-dns, load-balancing, database-operations, secret-management, infrastructure-security
- Learning paths organized by difficulty:
  - Beginner: Docker basics, first Terraform config, basic CI/CD pipelines
  - Intermediate: Multi-environment Terraform, Kubernetes patterns, monitoring stacks
  - Advanced: Multi-cloud architecture, GitOps workflows, chaos engineering, platform engineering
- 3 automated hooks for infrastructure workflow integration:
  - session-start.sh: Detects IaC tools, CI configs, cloud providers, container setup
  - pre-tool-use.sh: Warns on infrastructure file changes (state, secrets, networking)
  - post-tool-use.sh: Checks for hardcoded secrets, missing state backends, exposed ports
- DevOps-focused CLAUDE.md template for project configuration
- Beginner content: deploy-docker-app prompt, infrastructure vocabulary, pre-deployment checklist
- Project infrastructure: MIT license, contributing guidelines, code of conduct, issue templates
