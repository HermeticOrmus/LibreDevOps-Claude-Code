# /load-balance

Configure reverse proxies, tune upstreams, manage SSL termination, and implement traffic shaping patterns.

## Usage

```
/load-balance config|ssl|rate-limit|canary|debug [options]
```

## Actions

### `config`
Generate or review load balancer configuration.

```bash
# Test NGINX config before reload
nginx -t
nginx -T  # Dump full merged config

# Reload NGINX without downtime
nginx -s reload
systemctl reload nginx

# Test HAProxy config
haproxy -c -f /etc/haproxy/haproxy.cfg

# Reload HAProxy (hitless reload via socket)
haproxy -f /etc/haproxy/haproxy.cfg -p /var/run/haproxy.pid -sf $(cat /var/run/haproxy.pid)

# NGINX: check active connections per upstream server
nginx -V 2>&1 | grep -o with-http_stub_status_module
curl http://localhost/nginx_status

# View current upstream server states
echo "show servers state" | socat /run/haproxy/admin.sock -
echo "show info" | socat /run/haproxy/admin.sock -

# Drain a specific backend server (HAProxy)
echo "set server http_backend/app1 state drain" | socat /run/haproxy/admin.sock -
# Re-enable
echo "set server http_backend/app1 state ready" | socat /run/haproxy/admin.sock -
```

### `ssl`
Manage SSL/TLS certificates and configuration.

```bash
# Test TLS configuration
openssl s_client -connect api.example.com:443 -servername api.example.com
openssl s_client -connect api.example.com:443 -tls1_2  # Test TLS 1.2 support
openssl s_client -connect api.example.com:443 -tls1_3  # Test TLS 1.3

# Check certificate expiry
echo | openssl s_client -connect api.example.com:443 2>/dev/null | openssl x509 -noout -dates
echo | openssl s_client -connect api.example.com:443 2>/dev/null | openssl x509 -noout -subject -issuer

# Test cipher suites with nmap
nmap --script ssl-enum-ciphers -p 443 api.example.com

# Test with sslyze (comprehensive TLS audit)
sslyze --regular api.example.com:443

# Certbot: obtain Let's Encrypt cert (standalone)
certbot certonly --standalone -d api.example.com -d www.api.example.com

# Certbot: renew and reload NGINX
certbot renew --post-hook "nginx -s reload"

# Check OCSP stapling
openssl s_client -connect api.example.com:443 -status 2>/dev/null | grep -A 10 "OCSP Response"

# Verify HSTS preload eligibility
curl -sI https://api.example.com | grep Strict-Transport-Security
```

### `rate-limit`
Configure and test rate limiting.

```nginx
# NGINX: rate limit configuration
http {
    # Zone per IP: 10 req/s, 10MB shared memory
    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;

    # Zone per API key: different limit for authenticated clients
    map $http_authorization $rate_limit_key {
        default         $binary_remote_addr;  # Unauthenticated: by IP
        ~Bearer\s+(.+) $1;                    # Authenticated: by token
    }
    limit_req_zone $rate_limit_key zone=api_auth:10m rate=100r/s;

    server {
        location /api/ {
            limit_req zone=api burst=20 nodelay;
            limit_req_status 429;
            add_header Retry-After 1 always;
        }
    }
}
```

```bash
# Test rate limiting with hey (HTTP load generator)
hey -n 1000 -c 50 https://api.example.com/api/endpoint
# Expected: ~10 req/s pass, rest 429

# Test with Apache Bench
ab -n 100 -c 10 https://api.example.com/api/endpoint
# Check: "Non-2xx responses" count

# Monitor rate limit hits in NGINX logs
tail -f /var/log/nginx/error.log | grep "limiting requests"
```

### `canary`
Implement gradual traffic shifting for deployments.

```bash
# NGINX: weighted upstream (modify weight at runtime requires reload)
# 90% stable, 10% canary
cat << 'EOF' > /etc/nginx/conf.d/upstream.conf
split_clients "${remote_addr}${http_user_agent}" $backend {
    10%  canary_backend;
    *    stable_backend;
}
EOF
nginx -s reload

# AWS ALB: weighted target groups via CLI
# Shift 10% to canary
aws elbv2 modify-listener \
  --listener-arn arn:aws:elasticloadbalancing:us-east-1:ACCOUNT:listener/... \
  --default-actions 'Type=forward,ForwardConfig={TargetGroups=[{TargetGroupArn=arn:stable,Weight=90},{TargetGroupArn=arn:canary,Weight=10}]}'

# Shift to 50% canary
aws elbv2 modify-listener \
  --listener-arn $LISTENER_ARN \
  --default-actions 'Type=forward,ForwardConfig={TargetGroups=[{TargetGroupArn=arn:stable,Weight=50},{TargetGroupArn=arn:canary,Weight=50}]}'

# Full cutover to canary (promote to stable)
aws elbv2 modify-listener \
  --listener-arn $LISTENER_ARN \
  --default-actions "Type=forward,TargetGroupArn=$CANARY_ARN"

# Rollback (all traffic to stable)
aws elbv2 modify-listener \
  --listener-arn $LISTENER_ARN \
  --default-actions "Type=forward,TargetGroupArn=$STABLE_ARN"

# Kubernetes nginx-ingress: canary annotation
kubectl annotate ingress myapp-canary \
  nginx.ingress.kubernetes.io/canary-weight=10 \
  --overwrite -n production

# Increase canary to 50%
kubectl annotate ingress myapp-canary \
  nginx.ingress.kubernetes.io/canary-weight=50 \
  --overwrite -n production
```

### `debug`
Diagnose load balancer and upstream issues.

```bash
# Check which upstream server handled request (add $upstream_addr to log format)
tail -f /var/log/nginx/access.log | awk '{print $NF}'

# NGINX: enable upstream response time logging
log_format lb_debug '$remote_addr - $upstream_addr [$time_local] '
                    '"$request" $status $body_bytes_sent '
                    'rt=$request_time uct=$upstream_connect_time '
                    'uht=$upstream_header_time urt=$upstream_response_time';

# Test upstream directly (bypass LB)
curl -v http://10.0.1.10:8080/health

# Check which server a request routes to (via custom header)
curl -sI https://api.example.com/api/test | grep X-Served-By

# HAProxy: real-time stats
watch -n1 'echo "show stat" | socat /run/haproxy/admin.sock - | cut -d, -f1,2,4,5,7,8,18,19'

# Simulate upstream failure
# Mark server as down in HAProxy
echo "set server http_backend/app1 state maint" | socat /run/haproxy/admin.sock -
# Verify failover works, then restore
echo "set server http_backend/app1 state ready" | socat /run/haproxy/admin.sock -

# Test connection limits
curl -w "Connect: %{time_connect}s  Total: %{time_total}s\n" \
  -o /dev/null -s https://api.example.com/api/test

# Check 5xx error rate in real-time
tail -f /var/log/nginx/access.log | awk '$9 ~ /^5/ {count++} END {print count " 5xx errors"}'
```
