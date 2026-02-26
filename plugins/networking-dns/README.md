# Networking & DNS Plugin

VPC design, CIDR planning, Route53 routing policies, Transit Gateway, security groups, and Kubernetes DNS (CoreDNS/ExternalDNS).

## Components

- **Agent**: `network-engineer` -- VPC three-tier design, TGW vs peering, Route53 failover, security group least privilege
- **Command**: `/network` -- Manages VPCs, DNS records, security groups, and debugs connectivity
- **Skill**: `network-patterns` -- CIDR planning reference, VPC Endpoints Terraform, Route53 latency routing, CoreDNS config, DNS debug toolkit

## Quick Reference

```bash
# List VPCs with CIDR blocks
aws ec2 describe-vpcs --query 'Vpcs[*].{ID:VpcId,CIDR:CidrBlock}' --output table

# Check a DNS record
dig api.example.com A +short

# Trace DNS propagation
dig +trace api.example.com

# Check what Route53 health checks look like
aws route53 get-health-check-status --health-check-id $HC_ID

# Find security groups allowing 0.0.0.0/0
aws ec2 describe-security-groups \
  --filters "Name=ip-permission.cidr,Values=0.0.0.0/0" \
  --query 'SecurityGroups[*].{ID:GroupId,Port:IpPermissions[*].FromPort}'
```

## TTL Strategy

| Record Type | TTL | Reason |
|-------------|-----|--------|
| Production ALIAS (ALB) | 300s | AWS ALIAS records use ALB's TTL anyway |
| Database CNAME | 60s | Fast failover during RDS failover |
| Static content CDN | 86400s | Rarely changes |
| Health check failover | 60s | Route53 checks every 10s, client TTL should be short |
| Internal service records | 30s | Fast service discovery update |

**Rule**: Lower TTL before a planned failover or major change. Change TTL to 60s, wait for propagation (current TTL time), then make the change.

## Related Plugins

- [load-balancing](../load-balancing/) -- ALB/NLB as Route53 alias targets
- [aws-infrastructure](../aws-infrastructure/) -- VPC Terraform modules
- [kubernetes-operations](../kubernetes-operations/) -- CoreDNS, Service DNS
- [infrastructure-security](../infrastructure-security/) -- VPC Flow Logs analysis, NACLs
