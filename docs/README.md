# ListService Infrastructure – Documentation

This repository contains Terraform modules and environments to deploy the **ListService backend** on AWS ECS (Fargate).

📚 Documentation is split into sections:

1. [Architecture](01-architecture.md) – high-level design & diagram
2. [Modules](02-modules.md) – reusable Terraform modules
3. [Environments](03-environments.md) – CI, staging, production
4. [Security](04-security.md) – IAM roles, security groups, HTTPS
5. [Costs](05-costs.md) – monthly estimates per environment
6. [OIDC Setup](06-oidc.md) – GitHub → AWS federation (for CI/CD)
7. [CI Workflow](07-ci-workflow.md) – GitHub Actions Terraform pipeline
8. [Cleanup](08-cleanup.md) – helper scripts for teardown
