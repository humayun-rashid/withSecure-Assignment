# 1. Architecture

The ListService infrastructure is deployed to **AWS ECS (Fargate)** behind an **Application Load Balancer (ALB)**.  

## Diagram (conceptual)

            Internet
               │
        ┌──────▼───────┐
        │   ALB (HTTP) │
        │  (HTTPS opt.)│
        └──────┬───────┘
               │
      ┌────────▼────────┐
      │ ECS Service     │
      │ (Fargate tasks) │
      └────────┬────────┘
               │
          Private Subnets
               │
      ┌────────▼────────┐
      │    VPC (10.10.0.0/16)
      │   - Public subnets
      │   - Private subnets
      └──────────────────┘
               │
          NAT / IGW


## Key Components

- **ECS (Fargate)** – runs the backend container(s).
- **ALB** – routes traffic, health checks, TLS termination.
- **VPC** – networking backbone with public and private subnets.
- **CloudWatch** – observability (logs + alarms).
- **ECR** – container image storage.
