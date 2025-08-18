
---

# ☁️ ListService Infrastructure

This directory contains the **Terraform IaC** for provisioning and managing infrastructure for **ListService** across multiple environments.

---

## 📑 Table of Contents

1. [Overview](#-overview)
2. [OIDC & CI/CD Integration](#-oidc--cicd-integration)
3. [Architecture](#-architecture)
4. [Environments](#-environments)

   * [Global](#global)
   * [CI](#ci)
   * [Staging](#staging)
   * [Production](#production)
5. [Modules](#-modules)
6. [Scripts](#-scripts)
7. [Workflows](#-workflows)
8. [Smoke Testing](#-smoke-testing)

---

## 🚀 Overview

* **Terraform-first** infra management
* Environments: **Global**, **CI**, **Staging**, **Production**
* **OIDC-based GitHub Actions authentication** → no static AWS credentials needed
* Modular design with clear separation of reusable **modules/**
* Automated workflows for `plan`, `apply`, and `destroy`

---

## 🔐 OIDC & CI/CD Integration

To securely allow GitHub Actions to deploy infra and services:

1. **Create OIDC Identity Provider** in AWS for GitHub

   * Done via Terraform in **`global/`**
   * Configured trust policy maps GitHub org/repo to IAM roles
2. **IAM Roles for Deployments**:

   * `ListService-Global-Deploy` → allows infra/global to provision ECR, OIDC, base infra
   * `ListService-CI-Deploy` → allows CI workflows to deploy ECS services
   * Similar roles can be created for staging/prod
3. GitHub Actions assume these roles dynamically during workflows.

📜 Script: `bootstrap_tf_state.sh` also helps bootstrap **remote state** (S3 + DynamoDB backend).

---

## 🏗 Architecture

ASCII diagram:

```
GitHub Actions (OIDC)
        │
        ▼
 ┌───────────────┐
 │ AWS IAM Roles │  (ListService-Global-Deploy, ListService-CI-Deploy, etc.)
 └───────┬───────┘
         │
         ▼
 ┌─────────────────────────────┐
 │      AWS Infrastructure     │
 │ ─────────────────────────── │
 │  • VPC + Networking         │
 │  • ECS Fargate (Cluster/Svc)│
 │  • ALB (public entrypoint)  │
 │  • ECR (Docker registry)    │
 │  • Autoscaling + CW Logs    │
 └─────────────────────────────┘
```

---

## 🌍 Environments

### **Global**

* Location: `global/`
* One-time setup of shared resources:

  * **ECR Repository** (`listservice-global`)
  * **OIDC Provider** for GitHub Actions
  * **IAM Roles** for deployments
* Applied infrequently (when global infra changes).

---

### **CI**

* Location: `envs/ci/`
* Ephemeral environment for **continuous integration testing**
* Deployed automatically on PRs and `main` branch pushes
* Resources:

  * ECS cluster/service (`listservice-ci-cluster`)
  * ALB for external access
  * Networking (VPC, subnets, security groups)
* Workflows: `.github/workflows/infra-ci.yml`

---

### **Staging**

* Location: `envs/staging/`
* Stable **pre-production** environment
* Used for UAT and integration testing
* Mirrors production setup.

---

### **Production**

* Location: `envs/prod/`
* Full production environment
* Receives only **main branch releases**.
* Separate Terraform backend & state.

---

## 🧩 Modules

Reusable **modules/** define infra building blocks:

* `network/` → VPC, subnets, routing tables
* `ecs/` → ECS Fargate cluster, service, task defs
* `alb/` → Application Load Balancer + listeners
* `ecr/` → Elastic Container Registry
* `autoscaling/` → ECS task autoscaling
* `observability/` → CloudWatch logs, metrics, alarms

---

## 🛠 Scripts

Each environment has helper scripts (`envs/<env>/scripts/`):

* `plan.sh` → runs `terraform plan`
* `apply.sh` → runs `terraform apply`
* `destroy.sh` → runs `terraform destroy`
* `output.sh` → prints ALB DNS and other outputs
* `smoke-test.sh` → runs `/health` check on deployed ALB

Example for **CI env**:

```bash
cd envs/ci/scripts
./plan.sh      # dry run
./apply.sh     # deploy infra
./smoke-test.sh
./destroy.sh   # clean up
```

---

## 🔄 Workflows

Infra managed via **GitHub Actions**:

| Workflow            | Path                                  | Environment | Purpose                                  | Last Run                                                                                |
| ------------------- | ------------------------------------- | ----------- | ---------------------------------------- | --------------------------------------------------------------------------------------- |
| **Infra (Global)**  | `.github/workflows/infra-global.yml`  | Global      | Bootstraps shared infra (ECR, OIDC, IAM) | *add link*                                                                              |
| **Infra (CI)**      | `.github/workflows/infra-ci.yml`      | CI          | Creates ephemeral CI infra               | [Run](https://github.com/humayun-rashid/withSecure-Assignment/actions/runs/17027641526) |


---

⚡ With this setup:

* **Global** infra is bootstrapped once
* **CI/Staging/Prod** environments are managed independently
* **OIDC + GitHub Actions** enable secure, automated deployments with no static secrets

---

