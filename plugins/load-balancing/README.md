# Load Balancing Plugin

NGINX, HAProxy, AWS ALB/NLB, Kubernetes Ingress controllers, SSL/TLS termination, rate limiting, and canary traffic splitting.

## Components

- **Agent**: `lb-engineer` -- NGINX upstream tuning, HAProxy ACLs, ALB routing rules, nginx-ingress annotations, TLS best practices
- **Command**: `/load-balance` -- Generates configs, manages SSL certs, implements rate limiting, shifts canary traffic, debugs upstream failures
- **Skill**: `lb-patterns` -- Full NGINX production config, ALB Terraform, HAProxy with rate limiting, Traefik IngressRoute

## Quick Reference

```bash
# NGINX: test and reload config
nginx -t && nginx -s reload

# HAProxy: drain a server before maintenance
echo "set server http_backend/app1 state drain" | socat /run/haproxy/admin.sock -

# AWS ALB: shift 10% traffic to canary
aws elbv2 modify-listener --listener-arn $ARN \
  --default-actions 'Type=forward,ForwardConfig={TargetGroups=[{TargetGroupArn=arn:stable,Weight=90},{TargetGroupArn=arn:canary,Weight=10}]}'

# Kubernetes nginx-ingress: enable canary at 10%
kubectl annotate ingress myapp-canary \
  nginx.ingress.kubernetes.io/canary=true \
  nginx.ingress.kubernetes.io/canary-weight=10

# Test TLS config
openssl s_client -connect api.example.com:443 -servername api.example.com
```

## Algorithm Selection

| Scenario | Algorithm | Reason |
|----------|-----------|--------|
| Uniform REST APIs | Round-robin | Requests finish quickly, equal distribution is fine |
| File uploads + short requests | Least connections | Variable duration -- don't send upload to busy server |
| Non-shared sessions | IP hash | Same client always hits same backend |
| Mixed hardware capacity | Weighted | Send proportionally more to larger servers |

## Critical Production Settings

**keepalive to upstream**: Required. Without it, NGINX/HAProxy opens a new TCP connection for every request. Set `keepalive 64` in upstream block and `proxy_http_version 1.1; proxy_set_header Connection ""`.

**fail_timeout and max_fails**: Without these, NGINX retries a failed upstream indefinitely. Set `max_fails=3 fail_timeout=30s` per server.

**deregistration_delay (ALB)**: Set to 30s minimum. Without it, ALB may send requests to an ECS task that's already shutting down, causing connection resets.

**SSL session cache**: Set `ssl_session_cache shared:SSL:10m`. Without it, every connection does a full TLS handshake, wasting CPU and adding latency.

## Related Plugins

- [kubernetes-operations](../kubernetes-operations/) -- nginx-ingress, Traefik in Kubernetes
- [networking-dns](../networking-dns/) -- DNS-based routing, Route53 health checks
- [monitoring-observability](../monitoring-observability/) -- NGINX metrics via prometheus-nginx-exporter
- [service-mesh](../service-mesh/) -- Istio/Linkerd for east-west (pod-to-pod) load balancing
