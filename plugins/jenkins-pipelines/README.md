# Jenkins Pipelines Plugin

Declarative Jenkinsfiles, shared libraries, Kubernetes dynamic agents, JCasC configuration, and pipeline unit testing.

## Components

- **Agent**: `jenkins-engineer` -- Declarative pipeline structure, shared library design, JCasC, Kubernetes agents
- **Command**: `/jenkins` -- Generates Jenkinsfiles, scaffolds shared libraries, tests with JenkinsPipelineUnit, applies JCasC
- **Skill**: `jenkins-patterns` -- Complete pipeline with parallel stages, shared library vars, JCasC YAML, error handling

## Quick Reference

```groovy
// Jenkinsfile skeleton
@Library('jenkins-shared-library@main') _
pipeline {
    agent none
    options { timestamps(); timeout(time:30, unit:'MINUTES') }
    stages {
        stage('Build') {
            agent { label 'linux' }
            steps { sh 'docker build .' }
        }
    }
    post { always { cleanWs() } }
}
```

```bash
# Reload JCasC without restart
curl -X POST https://jenkins.example.com/configuration-as-code/reload \
  -H "Authorization: Bearer $TOKEN"

# Export current config
curl -s https://jenkins.example.com/configuration-as-code/export \
  -H "Authorization: Bearer $TOKEN" > jenkins-current.yml
```

## Key Patterns

**Declarative over scripted**: Declarative pipelines have clearer syntax, better visualization, and easier maintenance. Use `script {}` blocks only for logic that declarative can't express.

**Shared libraries for DRY**: When the same deployment steps appear in 3+ repos, extract to a shared library `vars/` function. Register the library in JCasC `globalLibraries`.

**Dynamic Kubernetes agents**: No persistent build agents needed. Each job gets a clean pod from the Kubernetes plugin. Specify multi-container pods for tools (docker-in-docker, kubectl, helm) without polluting a single image.

**JCasC for everything**: Never configure Jenkins through the UI in production. All configuration in `jenkins.yml` managed in version control. Reload without restart via the API.

## Related Plugins

- [github-actions](../github-actions/) -- Modern alternative for GitHub-hosted projects
- [gitlab-ci](../gitlab-ci/) -- GitLab alternative if using GitLab
- [kubernetes-operations](../kubernetes-operations/) -- Kubernetes plugin setup for dynamic agents
- [container-registry](../container-registry/) -- Registry auth in Jenkins credentials
