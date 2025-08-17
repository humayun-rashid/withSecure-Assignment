# 5. Cost Estimates

## CI (baseline)
- ECS (1 task, 256 CPU/512 MB): ~$15/mo
- ALB: ~$20/mo
- CloudWatch logs/metrics: ~$5/mo
- **Total: ~$40/mo**

## Staging
- ECS (2 tasks, NAT): ~$40/mo
- ALB w/ HTTPS: ~$20/mo
- NAT Gateway: ~$32/mo
- Logs/metrics: ~$10/mo
- **Total: ~$100/mo**

## Production
- ECS (4+ tasks): ~$80/mo+
- ALB + NATs: ~$50–70/mo
- Logs/alarms: ~$20/mo
- **Total: ~$150–200/mo**
