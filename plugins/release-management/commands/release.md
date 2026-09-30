# /release

Deploy, promote, and rollback releases using Helm, ArgoCD, Argo Rollouts, and semantic versioning.

## Usage

```
/release deploy|rollback|promote|status [options]
```

## Actions

### `deploy`
Deploy a new release.

```bash
# Helm: deploy with atomic rollback on failure
helm upgrade --install $APP ./charts/$APP \
  --namespace production \
  --values charts/$APP/values-production.yaml \
  --set image.tag=$IMAGE_TAG \
  --wait --timeout 5m --atomic

# Helm: dry-run first
helm upgrade --install $APP ./charts/$APP \
  --dry-run --debug \
  --values charts/$APP/values-production.yaml \
  --set image.tag=$IMAGE_TAG

# Helm: preview diff before deploying (helm-diff plugin)
helm diff upgrade $APP ./charts/$APP \
  --values charts/$APP/values-production.yaml \
  --set image.tag=$IMAGE_TAG

# kubectl: update image directly
kubectl set image deployment/$APP \
  app=registry.example.com/$APP:$IMAGE_TAG \
  -n production

# Wait for rollout
kubectl rollout status deployment/$APP -n production --timeout=5m

# ArgoCD: sync application (trigger deployment)
argocd app sync payment-api --prune
argocd app wait payment-api --health --timeout 300

# Argo Rollouts: check rollout status
kubectl argo rollouts get rollout payment-api -n production --watch
```

### `rollback`
Rollback a failed release.

```bash
# Helm: rollback to previous revision
helm rollback $APP -n production --wait

# Helm: rollback to specific revision
helm history $APP -n production          # List revisions
helm rollback $APP 3 -n production --wait

# kubectl: rollback deployment
kubectl rollout undo deployment/$APP -n production
kubectl rollout history deployment/$APP -n production
kubectl rollout undo deployment/$APP --to-revision=3 -n production

# Argo Rollouts: abort canary (stops at current step, does NOT rollback)
kubectl argo rollouts abort payment-api -n production
# Then undo to actually rollback
kubectl argo rollouts undo payment-api -n production

# ArgoCD: rollback to previous sync
argocd app history payment-api          # List sync IDs
argocd app rollback payment-api $SYNC_ID

# Verify rollback successful
kubectl get pods -n production -l app=$APP
kubectl rollout status deployment/$APP -n production
```

### `promote`
Promote a canary or staged release.

```bash
# Argo Rollouts: promote canary to next step
kubectl argo rollouts promote payment-api -n production

# Argo Rollouts: skip all steps and promote fully
kubectl argo rollouts promote payment-api -n production --full

# Check canary analysis results before promoting
kubectl argo rollouts get rollout payment-api -n production
kubectl describe analysisrun -n production | grep "Metric\|Value\|Status"

# AWS ALB: shift 50% traffic to canary
aws elbv2 modify-listener --listener-arn $LISTENER_ARN \
  --default-actions 'Type=forward,ForwardConfig={TargetGroups=[{TargetGroupArn='"$STABLE_TG"',Weight=50},{TargetGroupArn='"$CANARY_TG"',Weight=50}]}'

# AWS ALB: full cutover to canary (promote to stable)
aws elbv2 modify-listener --listener-arn $LISTENER_ARN \
  --default-actions "Type=forward,TargetGroupArn=$CANARY_TG"

# nginx-ingress: increase canary weight to 50%
kubectl annotate ingress $APP-canary \
  nginx.ingress.kubernetes.io/canary-weight=50 \
  --overwrite -n production
```

### `status`
Check release status across environments.

```bash
# Helm: all releases across namespaces
helm list -A --output table

# Helm: release details
helm status $APP -n production
helm get values $APP -n production     # Current values
helm get manifest $APP -n production   # Rendered manifests

# ArgoCD: all application statuses
argocd app list
argocd app get payment-api            # Detailed status

# Argo Rollouts: all rollouts
kubectl argo rollouts list rollouts -n production

# Check image tags running in production
kubectl get pods -n production -o jsonpath='{range .items[*]}{.spec.containers[*].image}{"\n"}{end}' | sort -u

# Compare deployed vs desired state
helm diff upgrade $APP ./charts/$APP \
  --values charts/$APP/values-production.yaml

# Semantic versioning: what changed since last release
git log $(git describe --tags --abbrev=0)..HEAD --oneline \
  | grep -E "^[a-f0-9]+ (feat|fix|perf|security|breaking)"

# Check deployment health
kubectl get deployment $APP -n production -o json | \
  jq '{desired: .spec.replicas, ready: .status.readyReplicas, updated: .status.updatedReplicas}'
```
