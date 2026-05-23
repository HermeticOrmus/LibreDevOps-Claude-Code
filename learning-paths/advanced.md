# Advanced — multi-region + FinOps + platform engineering

## Multi-region

- Active-active vs active-passive
- Data replication strategies (CRDTs, eventual consistency, strong consistency cost)
- Global load balancing (Cloud Load Balancer, Cloudflare, Anycast)
- DNS failover with health checks
- Disaster recovery: RTO + RPO targets per system

## FinOps

- Tagging strategy (every resource tagged with cost center)
- Reserved Instances + Savings Plans (1-3 year commits for steady workloads)
- Spot/preemptible for non-critical
- Right-sizing (VPA recommendations + manual review)
- Egress cost optimization (CDN, regional egress, content compression)
- Idle resource cleanup (orphaned EBS, unused ELBs, stopped instances incurring fees)

## Platform engineering

The job: build the platform that lets product teams ship without becoming SREs.

- Internal Developer Platform (IDP) — Backstage, Port, Cortex
- Golden paths — opinionated templates for common workloads
- Self-service — devs deploy without filing tickets
- Standardized observability across services
- Platform team as a product team (devs are users)
