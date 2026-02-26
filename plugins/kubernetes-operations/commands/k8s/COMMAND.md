# /k8s

Deploy workloads, scale services, debug pods, and manage Helm releases in Kubernetes clusters.

## Usage

```
/k8s deploy|scale|debug|upgrade [options]
```

## Actions

### `deploy`
Deploy or update Kubernetes workloads.

```bash
# Helm: install or upgrade
helm upgrade --install myapp ./charts/myapp \
  --namespace production \
  --create-namespace \
  --values ./charts/myapp/values-prod.yaml \
  --set image.tag=$IMAGE_TAG \
  --wait \
  --timeout 5m \
  --atomic    # Rollback automatically on failure

# Helm: dry run to preview changes
helm upgrade --install myapp ./charts/myapp \
  --dry-run \
  --debug \
  --set image.tag=$IMAGE_TAG

# Helm: diff (requires helm-diff plugin)
helm diff upgrade myapp ./charts/myapp \
  --values values-prod.yaml \
  --set image.tag=$IMAGE_TAG

# Direct kubectl: update image
kubectl set image deployment/myapp \
  app=registry.example.com/myapp:$IMAGE_TAG \
  -n production

# Wait for rollout to complete
kubectl rollout status deployment/myapp \
  -n production \
  --timeout=5m

# Apply manifests directory
kubectl apply -f kubernetes/ --dry-run=client  # Preview
kubectl apply -f kubernetes/ -n production

# Force rollout without image change (restart pods)
kubectl rollout restart deployment/myapp -n production
```

### `scale`
Scale deployments and configure autoscaling.

```bash
# Manual scale
kubectl scale deployment/myapp --replicas=5 -n production

# Check HPA status
kubectl get hpa -n production
kubectl describe hpa myapp-hpa -n production

# Check KEDA scaled object
kubectl get scaledobject -n production
kubectl describe scaledobject myworker-kafka-scaler -n production

# Resource usage (for rightsizing)
kubectl top pods -n production --sort-by=memory
kubectl top pods -n production --sort-by=cpu

# VPA recommendation (if VPA installed)
kubectl get vpa -n production -o yaml | \
  jq '.items[].status.recommendation.containerRecommendations[]'

# Simulate node pressure (for testing PDB)
kubectl drain node-1 --ignore-daemonsets --dry-run=true
```

### `debug`
Diagnose pod and cluster issues.

```bash
# Get pod details and events
kubectl describe pod $POD_NAME -n production | tail -40
kubectl get events -n production \
  --sort-by='.metadata.creationTimestamp' | tail -20

# View logs
kubectl logs $POD_NAME -n production
kubectl logs $POD_NAME -n production --previous  # Crashed/restarted container
kubectl logs -n production -l app=myapp --all-containers --prefix

# Stream logs from all pods with label
kubectl logs -n production -l app=myapp --follow --prefix

# Interactive shell (if image has shell)
kubectl exec -it $POD_NAME -n production -- sh
kubectl exec -it $POD_NAME -n production -c sidecar -- sh

# Ephemeral debug container (for distroless/minimal images)
kubectl debug -it pod/$POD_NAME \
  --image=busybox:latest \
  --target=myapp \
  -n production

# Network debug: test DNS resolution inside cluster
kubectl run -it --rm debug \
  --image=busybox --restart=Never -- \
  nslookup myapp.production.svc.cluster.local

# Network debug: test HTTP from inside cluster
kubectl run -it --rm curl \
  --image=curlimages/curl --restart=Never -- \
  curl http://myapp.production.svc.cluster.local/health

# Port-forward for local access
kubectl port-forward svc/myapp 8080:80 -n production

# Check container image and env
kubectl get pod $POD_NAME -n production -o json | \
  jq '.spec.containers[].{image: .image, env: .env}'

# Check what's being pulled
kubectl get events -n production | grep "Pulling\|Failed\|BackOff"
```

### `upgrade`
Manage cluster and workload upgrades.

```bash
# Rolling restart of all pods in deployment
kubectl rollout restart deployment/myapp -n production

# Rollback to previous version
kubectl rollout undo deployment/myapp -n production

# Rollback to specific revision
kubectl rollout undo deployment/myapp \
  --to-revision=3 \
  -n production

# Show rollout history
kubectl rollout history deployment/myapp -n production
kubectl rollout history deployment/myapp -n production --revision=3

# Helm rollback
helm rollback myapp 1 -n production  # Rollback to revision 1
helm history myapp -n production     # Show release history

# Node drain (for maintenance)
kubectl cordon node-1                            # Prevent new pods
kubectl drain node-1 \
  --ignore-daemonsets \
  --delete-emptydir-data \
  --timeout=60s
# ... perform maintenance ...
kubectl uncordon node-1                         # Re-enable scheduling
```
