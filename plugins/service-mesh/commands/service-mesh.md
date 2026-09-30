# /service-mesh

Configure Istio/Linkerd policies, debug service connectivity, and manage traffic routing at the mesh level.

## Usage

```
/service-mesh install|traffic|security|debug [options]
```

## Actions

### `install`
Install and configure service mesh components.

```bash
# Istio: install with production profile
istioctl install --set profile=production -y

# Istio: verify installation
istioctl verify-install
kubectl get pods -n istio-system

# Enable injection for namespace
kubectl label namespace production istio-injection=enabled --overwrite

# Restart existing pods to inject sidecars
kubectl rollout restart deployment -n production

# Verify injection
kubectl get pods -n production -o jsonpath='{.items[*].spec.containers[*].name}' | \
  tr ' ' '\n' | sort | uniq -c

# Linkerd: full install sequence
linkerd check --pre
linkerd install --crds | kubectl apply -f -
linkerd install | kubectl apply -f -
linkerd check
linkerd viz install | kubectl apply -f -
linkerd viz check

# Linkerd: inject existing deployments
kubectl get deploy -n production -o yaml | \
  linkerd inject - | kubectl apply -f -

# Check mesh control plane resource usage
kubectl top pods -n istio-system --sort-by=memory
```

### `traffic`
Manage traffic routing and policies.

```bash
# Apply VirtualService (canary routing)
kubectl apply -f virtualservice.yaml -n production

# Check VirtualService status
kubectl get virtualservice -n production
kubectl describe virtualservice payment-api -n production

# Verify DestinationRule subsets
kubectl get destinationrule -n production
kubectl describe destinationrule payment-api -n production

# Check what subset a pod belongs to (label-based)
kubectl get pod -n production -l app=payment-api -o json | \
  jq '.items[] | {name: .metadata.name, labels: .metadata.labels}'

# Test routing: send request with canary header
curl -H "x-canary: true" https://api.example.com/api/payments

# Verify traffic split is working (Linkerd)
linkerd viz routes deploy/ingress -n production --to deploy/payment-api

# Istio: view effective routing config for a pod
istioctl proxy-config routes pod/$POD_NAME -n production

# Apply fault injection for chaos testing
kubectl patch virtualservice payment-api -n production --type=merge -p '{
  "spec": {
    "http": [{
      "fault": {
        "abort": {
          "percentage": {"value": 5},
          "httpStatus": 503
        }
      },
      "route": [{"destination": {"host": "payment-api"}}]
    }]
  }
}'

# Remove fault injection
kubectl patch virtualservice payment-api -n production --type=merge -p '{
  "spec": {"http": [{"route": [{"destination": {"host": "payment-api"}}]}]}
}'
```

### `security`
Manage mTLS, authorization policies, and JWT authentication.

```bash
# Check mTLS status across namespace
istioctl authn tls-check -n production

# Check a specific service's mTLS status
istioctl authn tls-check payment-api.production.svc.cluster.local

# View authorization policies
kubectl get authorizationpolicy -n production
kubectl describe authorizationpolicy allow-frontend-to-payment -n production

# Check which certificates are active on a pod
istioctl proxy-config secret $POD_NAME -n production

# View certificate expiry
istioctl proxy-config secret $POD_NAME -n production -o json | \
  jq '.dynamicActiveSecrets[].secret.tlsCertificate.certificateChain.inlineBytes | @base64d' | \
  openssl x509 -noout -dates

# Linkerd: check mTLS between services
linkerd viz edges deploy -n production

# Test that plaintext is rejected (in STRICT mode)
kubectl run -it --rm test --image=curlimages/curl --restart=Never -n production -- \
  curl http://payment-api:80/health  # Should fail with mTLS STRICT
```

### `debug`
Diagnose mesh connectivity and performance issues.

```bash
# Istio: analyze config for issues
istioctl analyze -n production

# Check Envoy configuration for a specific pod
istioctl proxy-config cluster $POD_NAME -n production
istioctl proxy-config listener $POD_NAME -n production
istioctl proxy-config route $POD_NAME -n production

# Check Envoy stats for a service
kubectl port-forward $POD_NAME 15000:15000 -n production &
curl -s http://localhost:15000/stats | grep "cluster.outbound.*payment-api"

# Check circuit breaker status
curl -s http://localhost:15000/stats | grep "outlier_detection"
curl -s http://localhost:15000/stats | grep "ejections_active"

# Istio: check if a service is reachable from a pod
istioctl experimental workload entries list -n production

# Linkerd: debug slow requests
linkerd viz tap deploy/frontend -n production \
  --to deploy/payment-api \
  --path /api/payments \
  --method POST | \
  grep -E "rsp.*[0-9]{3,}ms"  # Responses slower than 100ms

# Check istiod logs for xDS issues
kubectl logs -n istio-system deploy/istiod | grep "ERROR\|WARN" | tail -20

# Check for sidecar injection issues
kubectl get events -n production | grep "injection\|sidecar"

# Enable debug logging for Envoy (specific logger)
kubectl exec -n production $POD_NAME -c istio-proxy -- \
  curl -s -X POST "http://localhost:15000/logging?http=debug"
# View the logs
kubectl logs -n production $POD_NAME -c istio-proxy | tail -50
```
