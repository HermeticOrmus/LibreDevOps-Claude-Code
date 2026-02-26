# /serverless

Deploy Lambda functions, manage API Gateway, monitor invocations, and debug serverless applications.

## Usage

```
/serverless deploy|invoke|logs|debug [options]
```

## Actions

### `deploy`
Deploy serverless functions and infrastructure.

```bash
# SAM: build and deploy
sam build
sam deploy --guided  # First time (creates samconfig.toml)
sam deploy           # Subsequent deploys (uses samconfig.toml)

# SAM: deploy to specific environment
sam deploy \
  --stack-name payment-processor-prod \
  --s3-bucket my-sam-artifacts \
  --parameter-overrides Environment=prod TableName=payments-prod \
  --capabilities CAPABILITY_IAM \
  --no-fail-on-empty-changeset

# Terraform: plan and apply Lambda changes
terraform plan -target=aws_lambda_function.payment_processor
terraform apply -target=aws_lambda_function.payment_processor

# Update Lambda code only (fast, no Terraform needed)
zip -r function.zip . -x '*.git*' '*.pyc' '__pycache__/*'
aws lambda update-function-code \
  --function-name payment-processor \
  --zip-file fileb://function.zip

# Or from ECR image
aws lambda update-function-code \
  --function-name payment-processor \
  --image-uri $ECR_REPO:$IMAGE_TAG

# Publish a new version and update alias
aws lambda publish-version --function-name payment-processor
aws lambda update-alias \
  --function-name payment-processor \
  --name prod \
  --function-version $NEW_VERSION

# Set provisioned concurrency
aws lambda put-provisioned-concurrency-config \
  --function-name payment-processor \
  --qualifier prod \
  --provisioned-concurrent-executions 5
```

### `invoke`
Test Lambda functions directly.

```bash
# Invoke synchronously and view response
aws lambda invoke \
  --function-name payment-processor \
  --payload '{"payment_id": "test_123", "amount": 100}' \
  --cli-binary-format raw-in-base64-out \
  --log-type Tail \
  output.json && cat output.json

# Invoke asynchronously (event = fire and forget)
aws lambda invoke \
  --function-name payment-processor \
  --invocation-type Event \
  --payload '{"payment_id": "test_456"}' \
  --cli-binary-format raw-in-base64-out \
  /dev/null

# Invoke with SQS event shape (simulate SQS trigger)
aws lambda invoke \
  --function-name payment-processor \
  --payload '{
    "Records": [{
      "messageId": "test-id",
      "receiptHandle": "test-handle",
      "body": "{\"payment_id\": \"test_789\", \"amount\": 50}",
      "attributes": {}
    }]
  }' \
  --cli-binary-format raw-in-base64-out \
  output.json

# SAM: invoke locally (with real AWS services via env vars)
sam local invoke PaymentProcessor \
  --event events/sqs-event.json \
  --env-vars env.json

# SAM: start local API (emulate API Gateway)
sam local start-api --port 3000 --env-vars env.json
curl -X POST http://localhost:3000/payments -d '{"amount":100}'
```

### `logs`
View Lambda logs and metrics.

```bash
# Tail live logs
aws logs tail /aws/lambda/payment-processor --follow --format short

# Filter for errors only
aws logs tail /aws/lambda/payment-processor --follow \
  --filter-pattern "ERROR"

# Get logs for a specific request ID
aws logs filter-log-events \
  --log-group-name /aws/lambda/payment-processor \
  --filter-pattern '"request_id" "abc-123"' \
  --start-time $(date -d '-1h' +%s)000

# SAM logs (wraps aws logs with function name lookup)
sam logs -n PaymentProcessor --stack-name payment-processor-prod --tail

# Structured log query with CloudWatch Insights
aws logs start-query \
  --log-group-name /aws/lambda/payment-processor \
  --start-time $(date -d '-1h' +%s) \
  --end-time $(date +%s) \
  --query-string '
    fields @timestamp, @message, level, payment_id, duration_ms
    | filter level = "ERROR"
    | sort @timestamp desc
    | limit 50
  '

# Check cold start rate
aws logs start-query \
  --log-group-name /aws/lambda/payment-processor \
  --start-time $(date -d '-24h' +%s) \
  --end-time $(date +%s) \
  --query-string '
    filter @type = "REPORT"
    | stats count(*) as total,
            sum(ispresent(@initDuration)) as coldStarts,
            avg(@initDuration) as avgColdStartMs
  '
```

### `debug`
Diagnose Lambda and API Gateway issues.

```bash
# Check function configuration
aws lambda get-function-configuration \
  --function-name payment-processor \
  --query '{Runtime:Runtime,Timeout:Timeout,Memory:MemorySize,Env:Environment.Variables}'

# Check concurrency limits
aws lambda get-function-concurrency --function-name payment-processor
aws lambda get-account-settings  # Regional limits

# Check throttle rate
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Throttles \
  --dimensions Name=FunctionName,Value=payment-processor \
  --start-time $(date -d '-1h' -u +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 60 \
  --statistics Sum

# Check DLQ for failed events
aws sqs get-queue-attributes \
  --queue-url $DLQ_URL \
  --attribute-names ApproximateNumberOfMessages

# Receive and inspect DLQ messages
aws sqs receive-message --queue-url $DLQ_URL | \
  jq '.Messages[].Body | fromjson'

# Check API Gateway 4xx/5xx errors
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApiGateway \
  --metric-name 5XXError \
  --dimensions Name=ApiName,Value=payment-api Name=Stage,Value=prod \
  --start-time $(date -d '-1h' -u +%Y-%m-%dT%H:%M:%SZ) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
  --period 300 \
  --statistics Sum

# X-Ray traces: find slow invocations
aws xray get-service-graph \
  --start-time $(date -d '-1h' +%s) \
  --end-time $(date +%s)
```
