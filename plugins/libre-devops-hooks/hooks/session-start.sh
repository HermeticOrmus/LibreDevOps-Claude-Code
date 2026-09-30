#!/usr/bin/env bash
# =============================================================================
# LibreDevOps SessionStart hook
# =============================================================================
# When a session opens in an infrastructure or DevOps project, print one line
# of context for Claude: IaC tools, CI/CD systems, cloud providers, container
# and orchestration setup, monitoring stack, security tooling, the most
# important infrastructure warnings, and the LibreDevOps plugins that fit.
#
# Quiet by design: prints nothing outside infrastructure projects, writes no
# files, and never fails the session (every check is best effort).
#
# Input:  hook JSON on stdin (uses .cwd)
# Output: one plain-text line on stdout, which Claude Code adds to context
# Needs:  jq (exits silently without it)
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

command -v jq >/dev/null 2>&1 || exit 0

INPUT="$(cat || true)"
DIR="$(jq -r '.cwd // empty' <<<"$INPUT" 2>/dev/null || true)"
[[ -n "$DIR" && -d "$DIR" ]] || DIR="$PWD"

# First match of a find expression, skipping vendored and generated trees.
first_match() {
  find "$DIR" -maxdepth 3 \
    \( -name node_modules -o -name .git -o -name .terraform -o -name vendor -o -name .venv \) -prune \
    -o \( "$@" \) -print -quit 2>/dev/null || true
}
exists() { [[ -e "$DIR/$1" ]]; }
join() { local out="" item; for item in "$@"; do out+="${out:+, }$item"; done; printf '%s' "$out"; }

# Terraform and YAML files (bounded, for content checks).
TF_FILES=()
while IFS= read -r f; do TF_FILES+=("$f"); done < <(
  find "$DIR" -maxdepth 3 \( -name node_modules -o -name .git -o -name .terraform -o -name vendor \) -prune \
    -o -name '*.tf' -print 2>/dev/null | head -n 500 || true)
YAML_FILES=()
while IFS= read -r f; do YAML_FILES+=("$f"); done < <(
  find "$DIR" -maxdepth 3 \( -name node_modules -o -name .git -o -name .terraform -o -name vendor \) -prune \
    -o \( -name '*.yaml' -o -name '*.yml' -o -name '*.json' \) -print 2>/dev/null | head -n 500 || true)

tf_has()   { (( ${#TF_FILES[@]} > 0 )) && grep -qE -- "$1" "${TF_FILES[@]}" 2>/dev/null; }
yaml_has() { (( ${#YAML_FILES[@]} > 0 )) && grep -qE -- "$1" "${YAML_FILES[@]}" 2>/dev/null; }

IS_GIT=false
if [[ -e "$DIR/.git" ]] && command -v git >/dev/null 2>&1; then IS_GIT=true; fi
tracked() { [[ "$IS_GIT" == true ]] && [[ -n "$(git -C "$DIR" ls-files -- "$@" 2>/dev/null | head -n 1 || true)" ]]; }

IAC=(); CI=(); CLOUD=(); CONTAINERS=(); MONITORING=(); SECURITY=()
CRITICAL=(); WARNINGS=(); PLUGINS=()

# --- Infrastructure as code -------------------------------------------------
if (( ${#TF_FILES[@]} > 0 )); then
  IAC+=("Terraform"); PLUGINS+=("terraform-patterns")
  if ! tf_has 'backend[[:space:]]+"(s3|gcs|azurerm|remote|consul|http|pg|kubernetes)"|^[[:space:]]*cloud[[:space:]]*\{'; then
    WARNINGS+=("no remote Terraform backend")
  fi
  if tracked '*.tfstate' '*.tfstate.backup'; then
    CRITICAL+=("Terraform state committed to git")
  fi
fi
exists Pulumi.yaml && IAC+=("Pulumi")
yaml_has 'AWSTemplateFormatVersion' && IAC+=("CloudFormation")
exists cdk.json && IAC+=("AWS CDK")
if exists ansible.cfg || exists playbook.yml || exists playbooks || exists roles; then
  IAC+=("Ansible"); PLUGINS+=("ansible-automation")
fi
exists Vagrantfile && IAC+=("Vagrant")
[[ -n "$(first_match -name '*.pkr.hcl' -o -name '*.pkr.json')" ]] && IAC+=("Packer")
for tool in ${IAC[@]+"${IAC[@]}"}; do
  case "$tool" in Pulumi|CloudFormation|"AWS CDK") PLUGINS+=("aws-infrastructure") ;; esac
done

# --- CI/CD -------------------------------------------------------------------
exists .github/workflows && { CI+=("GitHub Actions"); PLUGINS+=("github-actions"); }
exists .gitlab-ci.yml && { CI+=("GitLab CI"); PLUGINS+=("gitlab-ci"); }
exists Jenkinsfile && { CI+=("Jenkins"); PLUGINS+=("jenkins-pipelines"); }
exists .circleci/config.yml && CI+=("CircleCI")
exists .travis.yml && CI+=("Travis CI")
exists .buildkite && CI+=("Buildkite")
exists azure-pipelines.yml && CI+=("Azure Pipelines")
exists bitbucket-pipelines.yml && CI+=("Bitbucket Pipelines")
exists .drone.yml && CI+=("Drone CI")

# --- Cloud providers (from Terraform) ------------------------------------------
tf_has 'provider[[:space:]]+"aws"|"aws_' && { CLOUD+=("AWS"); PLUGINS+=("aws-infrastructure"); }
tf_has 'provider[[:space:]]+"google"|"google_' && { CLOUD+=("GCP"); PLUGINS+=("gcp-infrastructure"); }
tf_has 'provider[[:space:]]+"azurerm"|"azurerm_' && { CLOUD+=("Azure"); PLUGINS+=("azure-infrastructure"); }
tf_has 'provider[[:space:]]+"digitalocean"' && CLOUD+=("DigitalOcean")

# --- Containers and orchestration -----------------------------------------------
COMPOSE=""
for f in docker-compose.yml docker-compose.yaml compose.yml compose.yaml; do
  if exists "$f"; then COMPOSE="$DIR/$f"; break; fi
done
if exists Dockerfile || [[ -n "$COMPOSE" ]]; then
  CONTAINERS+=("Docker"); PLUGINS+=("docker-orchestration")
  if exists Dockerfile; then
    grep -qE '^USER[[:space:]]' "$DIR/Dockerfile" 2>/dev/null || WARNINGS+=("Dockerfile runs as root")
    grep -qE '^FROM[[:space:]]+[^[:space:]]+:latest([[:space:]]|$)|^FROM[[:space:]]+[^[:space:]:@]+[[:space:]]*$' "$DIR/Dockerfile" 2>/dev/null \
      && WARNINGS+=("Dockerfile base image unpinned")
    grep -qE '^HEALTHCHECK' "$DIR/Dockerfile" 2>/dev/null || WARNINGS+=("Dockerfile has no HEALTHCHECK")
  fi
  if [[ -n "$COMPOSE" ]] && ! grep -qE 'deploy:|resources:|mem_limit|cpus:' "$COMPOSE" 2>/dev/null; then
    WARNINGS+=("compose has no resource limits")
  fi
fi
if exists k8s || exists kubernetes || exists manifests || exists deploy; then
  CONTAINERS+=("Kubernetes"); PLUGINS+=("kubernetes-operations")
fi
if exists charts || exists Chart.yaml || exists helm; then
  CONTAINERS+=("Helm"); PLUGINS+=("kubernetes-operations")
fi
[[ -n "$(first_match -name kustomization.yaml -o -name kustomization.yml)" ]] && CONTAINERS+=("Kustomize")

# --- Monitoring ------------------------------------------------------------------
[[ -n "$(first_match -name prometheus.yml -o -name prometheus.yaml)" ]] && MONITORING+=("Prometheus")
[[ -n "$(first_match -name 'grafana*')" ]] && MONITORING+=("Grafana")
[[ -n "$(first_match -name 'datadog*')" ]] && MONITORING+=("Datadog")
tf_has 'aws_cloudwatch' && MONITORING+=("CloudWatch")
yaml_has 'opentelemetry|otel-collector|otlp' && MONITORING+=("OpenTelemetry")
(( ${#MONITORING[@]} > 0 )) && PLUGINS+=("monitoring-observability")

# Not an infrastructure project: stay silent.
if (( ${#IAC[@]} + ${#CI[@]} + ${#CONTAINERS[@]} + ${#MONITORING[@]} == 0 )); then
  exit 0
fi

# --- Security tooling -------------------------------------------------------------
{ exists .trivyignore || exists trivy.yaml; } && SECURITY+=("Trivy")
{ exists .tfsec.yml || exists .tfsec; } && SECURITY+=("tfsec")
{ exists .checkov.yml || exists .checkov.yaml; } && SECURITY+=("Checkov")
exists .gitleaks.toml && SECURITY+=("Gitleaks")
exists .snyk && SECURITY+=("Snyk")
exists .github/dependabot.yml && SECURITY+=("Dependabot")
{ exists renovate.json || exists .renovaterc.json; } && SECURITY+=("Renovate")

# --- Repository hygiene -------------------------------------------------------------
if [[ "$IS_GIT" == true ]]; then
  if [[ ! -f "$DIR/.gitignore" ]]; then
    CRITICAL+=("no .gitignore")
  else
    if (( ${#TF_FILES[@]} > 0 )) && ! grep -qE 'tfstate|\.terraform' "$DIR/.gitignore"; then
      WARNINGS+=(".gitignore misses Terraform state")
    fi
    grep -qE '^\.env$|^\*\.env|^\.env\*|^\.env\.' "$DIR/.gitignore" || WARNINGS+=(".gitignore misses .env")
  fi
  tracked .env .env.local .env.production && CRITICAL+=(".env committed to git")
  tracked '*.pem' '*.key' '*.p12' '*.pfx' && CRITICAL+=("private keys committed to git")
fi
if (( ${#IAC[@]} > 0 )); then
  (( ${#MONITORING[@]} == 0 )) && WARNINGS+=("no monitoring config")
  (( ${#SECURITY[@]} == 0 )) && WARNINGS+=("no IaC security scanning")
  PLUGINS+=("secret-management" "infrastructure-security")
fi

# --- One line of context ------------------------------------------------------------
PARTS=()
(( ${#IAC[@]} ))        && PARTS+=("IaC: $(join "${IAC[@]}")")
(( ${#CI[@]} ))         && PARTS+=("CI/CD: $(join "${CI[@]}")")
(( ${#CLOUD[@]} ))      && PARTS+=("cloud: $(join "${CLOUD[@]}")")
(( ${#CONTAINERS[@]} )) && PARTS+=("containers: $(join "${CONTAINERS[@]}")")
(( ${#MONITORING[@]} )) && PARTS+=("monitoring: $(join "${MONITORING[@]}")")
(( ${#SECURITY[@]} ))   && PARTS+=("security tools: $(join "${SECURITY[@]}")")

ALL_WARN=(${CRITICAL[@]+"${CRITICAL[@]}"} ${WARNINGS[@]+"${WARNINGS[@]}"})
if (( ${#ALL_WARN[@]} > 4 )); then
  WARN_TEXT="$(join "${ALL_WARN[@]:0:4}") (+$(( ${#ALL_WARN[@]} - 4 )) more)"
elif (( ${#ALL_WARN[@]} > 0 )); then
  WARN_TEXT="$(join "${ALL_WARN[@]}")"
else
  WARN_TEXT=""
fi

SUGGESTED=()
while IFS= read -r p; do [[ -n "$p" ]] && SUGGESTED+=("$p"); done < <(printf '%s\n' ${PLUGINS[@]+"${PLUGINS[@]}"} | sort -u)

LINE="LibreDevOps: $(printf '%s; ' "${PARTS[@]}")"
LINE="${LINE%; }."
[[ -n "$WARN_TEXT" ]] && LINE+=" Check: $WARN_TEXT."
(( ${#SUGGESTED[@]} )) && LINE+=" Relevant plugins: $(join "${SUGGESTED[@]}")."
printf '%s\n' "$LINE"
exit 0
