# Serverless Patterns Plugin

AWS Lambda, API Gateway, Step Functions, EventBridge, SQS event-driven patterns, DynamoDB single-table design, and cold start optimization.

## Components

- **Agent**: `serverless-architect` -- Lambda best practices, API Gateway REST vs HTTP, Step Functions workflow design, cold start mitigation, when NOT to use serverless
- **Command**: `/serverless` -- Deploys functions, invokes for testing, tails logs, debugs throttles and DLQ issues
- **Skill**: `serverless-patterns` -- Lambda Terraform with VPC/provisioned concurrency, SAM template, EventBridge rule, DynamoDB single-table pattern

## Quick Reference

```bash
# Deploy with SAM
sam build && sam deploy

# Invoke a function with a test payload
aws lambda invoke \
  --function-name myfunction \
  --payload '{"key":"value"}' \
  --cli-binary-format raw-in-base64-out \
  --log-type Tail output.json

# Tail logs live
aws logs tail /aws/lambda/myfunction --follow --format short

# Check DLQ depth
aws sqs get-queue-attributes --queue-url $DLQ_URL \
  --attribute-names ApproximateNumberOfMessages
```

## Cold Start Cheat Sheet

| Language | Typical Cold Start | Mitigation |
|----------|-------------------|------------|
| Python | 300-800ms | Reduce package size, Lambda Layers |
| Node.js | 200-600ms | Reduce imports, tree-shake |
| Go | 50-200ms | Native binary, very fast |
| Java | 1-3s | SnapStart (Java 11+) |
| Container | 1-5s | Provisioned concurrency |

**Provisioned Concurrency**: Eliminates cold starts but costs ~40% of always-warm. Worth it for user-facing latency-sensitive APIs.

## Serverless vs Containers

| Use Serverless When | Use Containers (Fargate) When |
|---------------------|-------------------------------|
| Event-driven, infrequent | High, steady traffic |
| Burst traffic (0 to 1000 instantly) | Long-running processes |
| <15 min execution | Consistent P99 latency required |
| Pay per request | Persistent TCP connections (WebSocket, gRPC) |

## Related Plugins

- [aws-infrastructure](../aws-infrastructure/) -- VPC, IAM for Lambda
- [monitoring-observability](../monitoring-observability/) -- Lambda metrics, X-Ray
- [secret-management](../secret-management/) -- Secrets Manager in Lambda
- [database-operations](../database-operations/) -- DynamoDB, RDS Proxy for Lambda
