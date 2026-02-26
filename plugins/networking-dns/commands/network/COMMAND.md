# /network

Design VPCs, manage DNS records, configure routing policies, and debug network connectivity.

## Usage

```
/network vpc|dns|security|debug [options]
```

## Actions

### `vpc`
Create and manage VPC infrastructure.

```bash
# List VPCs and their CIDR blocks
aws ec2 describe-vpcs --query 'Vpcs[*].{ID:VpcId,CIDR:CidrBlock,Name:Tags[?Key==`Name`].Value|[0]}' --output table

# Show subnet details with AZ
aws ec2 describe-subnets \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'Subnets[*].{ID:SubnetId,AZ:AvailabilityZone,CIDR:CidrBlock,Public:MapPublicIpOnLaunch}' \
  --output table

# Check route tables
aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'RouteTables[*].{ID:RouteTableId,Routes:Routes[*].{Dest:DestinationCidrBlock,Gateway:GatewayId}}'

# Check NAT Gateway status
aws ec2 describe-nat-gateways \
  --filter "Name=vpc-id,Values=$VPC_ID" \
  --query 'NatGateways[*].{ID:NatGatewayId,State:State,AZ:SubnetId}'

# Show VPC Flow Log traffic to/from an IP
aws logs filter-log-events \
  --log-group-name /aws/vpc/flowlogs/$VPC_ID \
  --filter-pattern "[version, account, intf, srcAddr=$TARGET_IP, ...]" \
  --start-time $(date -d '-15 minutes' +%s)000

# Find which security group is blocking traffic (VPC Reachability Analyzer)
aws ec2 start-network-insights-analysis \
  --network-insights-path-id $(
    aws ec2 create-network-insights-path \
      --source $SOURCE_ENI \
      --destination $DEST_ENI \
      --protocol TCP \
      --destination-port 5432 \
      --query 'NetworkInsightsPath.NetworkInsightsPathId' \
      --output text
  ) --query 'NetworkInsightsAnalysis.NetworkInsightsAnalysisId' --output text
```

### `dns`
Manage Route53 records and hosted zones.

```bash
# List hosted zones
aws route53 list-hosted-zones --query 'HostedZones[*].{Name:Name,ID:Id,Private:Config.PrivateZone}'

# Get all records in a zone
aws route53 list-resource-record-sets \
  --hosted-zone-id $ZONE_ID \
  --query 'ResourceRecordSets[*].{Name:Name,Type:Type,TTL:TTL}'

# Create/update A record
aws route53 change-resource-record-sets \
  --hosted-zone-id $ZONE_ID \
  --change-batch '{
    "Changes": [{
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "api.example.com",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [{"Value": "1.2.3.4"}]
      }
    }]
  }'

# Create weighted routing records
aws route53 change-resource-record-sets \
  --hosted-zone-id $ZONE_ID \
  --change-batch file://weighted-records.json

# Check pending change status
aws route53 get-change --id $CHANGE_ID \
  --query 'ChangeInfo.Status'

# List health checks and their status
aws route53 list-health-checks --query 'HealthChecks[*].{ID:Id,FQDN:HealthCheckConfig.FullyQualifiedDomainName,Status:?}'
aws route53 get-health-check-status --health-check-id $HC_ID

# Export zone as zone file
aws route53 list-resource-record-sets --hosted-zone-id $ZONE_ID > zone-backup.json

# Check if ExternalDNS is managing a record (TXT ownership record)
dig TXT "externaldns-api.example.com" +short
```

### `security`
Manage security groups and NACLs.

```bash
# List security groups with their rules
aws ec2 describe-security-groups \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'SecurityGroups[*].{ID:GroupId,Name:GroupName,Inbound:IpPermissions,Outbound:IpPermissionsEgress}'

# Find security groups allowing 0.0.0.0/0 inbound (security audit)
aws ec2 describe-security-groups \
  --filters "Name=ip-permission.cidr,Values=0.0.0.0/0" \
  --query 'SecurityGroups[*].{ID:GroupId,Name:GroupName,Port:IpPermissions[*].FromPort}'

# Add ingress rule to security group
aws ec2 authorize-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0

# Remove ingress rule
aws ec2 revoke-security-group-ingress \
  --group-id $SG_ID \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0

# Check NACL rules for a subnet
aws ec2 describe-network-acls \
  --filters "Name=association.subnet-id,Values=$SUBNET_ID" \
  --query 'NetworkAcls[*].Entries[*].{Rule:RuleNumber,Protocol:Protocol,Action:RuleAction,CIDR:CidrBlock,Port:PortRange}'
```

### `debug`
Diagnose connectivity and routing issues.

```bash
# Test TCP connectivity from inside ECS/Lambda (via SSM)
aws ssm start-session --target $INSTANCE_ID \
  --document-name AWS-StartInteractiveCommand \
  --parameters 'command=["nc -zv postgres.internal.example.com 5432 -w 5"]'

# Trace route to identify hops
traceroute -T -p 443 api.example.com  # TCP traceroute

# Check if port is reachable (without installing tools)
timeout 5 bash -c "</dev/tcp/postgres.internal/5432" && echo "open" || echo "closed"

# Decode VPC Flow Logs (find rejected traffic)
aws logs filter-log-events \
  --log-group-name /aws/vpc/flowlogs \
  --filter-pattern "[version, account, intf, src, dst, srcPort, dstPort, protocol, packets, bytes, start, end, action=REJECT, ...]" \
  --start-time $(date -d '-30 minutes' +%s)000 | \
  jq -r '.events[].message' | awk '{print "From:", $4, "To:", $5, "Port:", $7, "Action:", $13}'

# Check Transit Gateway route table
aws ec2 search-transit-gateway-routes \
  --transit-gateway-route-table-id $TGW_RT_ID \
  --filters "Name=state,Values=active" \
  --query 'Routes[*].{Dest:DestinationCidrBlock,Attachment:TransitGatewayAttachments[0].TransitGatewayAttachmentId}'

# DNS resolution order check (from Linux)
systemd-resolve --status
cat /etc/resolv.conf

# Test Route53 private zone resolution from EC2
dig @169.254.169.253 postgres.internal.example.com A +short

# MTR (My Traceroute) - real-time route analysis
mtr --report --tcp --port 443 api.example.com
```
