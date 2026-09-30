# /jenkins

Create Jenkinsfiles, configure shared libraries, set up Kubernetes dynamic agents, and manage JCasC.

## Usage

```
/jenkins create|shared-lib|test|configure [options]
```

## Actions

### `create`
Generate a declarative Jenkinsfile.

```groovy
// Minimal CI Jenkinsfile
pipeline {
    agent { label 'linux' }

    environment {
        IMAGE = "registry.example.com/myapp:${env.GIT_COMMIT[0..7]}"
    }

    options {
        timeout(time: 20, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '20'))
        timestamps()
    }

    stages {
        stage('Build')  { steps { sh 'docker build -t $IMAGE .' } }
        stage('Test')   { steps { sh 'npm test' } }
        stage('Push')   { steps { sh 'docker push $IMAGE' } }
    }

    post {
        failure { mail to: 'team@example.com', subject: "Build failed: ${env.JOB_NAME}", body: env.BUILD_URL }
    }
}
```

### `shared-lib`
Set up shared library structure and example vars.

```bash
# Create shared library repo structure
mkdir -p jenkins-shared-library/{vars,src/com/example/ci,test/unit}

# Register in Jenkins (JCasC)
# unclassified.globalLibraries.libraries[0]:
#   name: jenkins-shared-library
#   defaultVersion: main
#   retriever.modernSCM.scm.git.remote: https://github.com/myorg/jenkins-shared-library.git
```

```groovy
// vars/runTests.groovy - multi-language test runner
def call(Map config = [:]) {
    def lang    = config.lang    ?: detectLanguage()
    def timeout = config.timeout ?: 10

    stage('Test') {
        timeout(time: timeout, unit: 'MINUTES') {
            switch(lang) {
                case 'node':
                    sh 'npm ci && npm test'
                    break
                case 'python':
                    sh 'pip install -r requirements.txt && pytest --junitxml=results.xml'
                    break
                case 'go':
                    sh 'go test ./... -v'
                    break
                default:
                    error("Unknown language: ${lang}")
            }
        }
    }
}

def detectLanguage() {
    if (fileExists('package.json')) return 'node'
    if (fileExists('requirements.txt')) return 'python'
    if (fileExists('go.mod')) return 'go'
    return 'unknown'
}
```

### `test`
Unit test pipeline logic with JenkinsPipelineUnit.

```groovy
// build.gradle (test dependencies)
testImplementation 'com.lesfurets:jenkins-pipeline-unit:1.23'
testImplementation 'org.junit.jupiter:junit-jupiter-api:5.10.0'
testRuntimeOnly 'org.junit.jupiter:junit-jupiter-engine:5.10.0'
```

```groovy
// test/unit/RunTestsTest.groovy
import com.lesfurets.jenkins.unit.BasePipelineTest
import org.junit.jupiter.api.Test

class RunTestsTest extends BasePipelineTest {
    @Test
    void testRunTests_nodeProject() {
        binding.setVariable('env', [:])
        helper.registerAllowedMethod('sh', [String]) {}
        helper.registerAllowedMethod('stage', [String, Closure]) { name, c -> c() }
        helper.registerAllowedMethod('timeout', [Map, Closure]) { m, c -> c() }
        helper.registerAllowedMethod('fileExists', [String]) { f -> f == 'package.json' }

        def script = loadScript('vars/runTests.groovy')
        script.call()

        def shCalls = helper.callStack.findAll { it.methodName == 'sh' }
        assertTrue(shCalls.any { it.args[0] == 'npm ci && npm test' })
    }
}
```

### `configure`
Apply JCasC configuration.

```bash
# Validate JCasC config before applying
docker run --rm \
  -v $(pwd)/jenkins.yml:/config/jenkins.yml \
  jenkins/jenkins:lts \
  java -jar /usr/share/jenkins/jenkins.war \
  --httpPort=-1 \
  --casc-validation-config=/config/jenkins.yml

# Reload JCasC on running Jenkins (no restart)
curl -X POST \
  "https://jenkins.example.com/configuration-as-code/reload" \
  -H "Authorization: Bearer $JENKINS_TOKEN"

# Export current Jenkins config to JCasC format
curl -s "https://jenkins.example.com/configuration-as-code/export" \
  -H "Authorization: Bearer $JENKINS_TOKEN" \
  > jenkins-current.yml

# Check plugin versions
curl -s "https://jenkins.example.com/pluginManager/api/json?depth=1" \
  -H "Authorization: Bearer $JENKINS_TOKEN" | \
  jq '.plugins[] | {name: .shortName, version: .version}' | \
  head -40
```
