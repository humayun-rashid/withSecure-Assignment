
---

# ☁️ ListService Infrastructure

This repository defines the **infrastructure-as-code (IaC)** for **ListService**, using **Terraform**, with secure **OIDC-based GitHub Actions deployments**, modular design, and multi-environment separation.

---

## 📑 Table of Contents

1. [Overview](#-overview)
2. [Architecture](#-architecture)
3. [Environments](#-environments)

   * [Global](#global)
   * [CI](#ci)
   * [Staging](#staging)
   * [Production](#production)
4. [State Bootstrapping](#-state-bootstrapping)
5. [OIDC & IAM Setup](#-oidc--iam-setup)
6. [Modules](#-modules)
7. [Scripts](#-scripts)
8. [Workflows](#-workflows)

---

## 🚀 Overview

* **Terraform-first** infra management
* **Remote state** stored in S3 + DynamoDB (per env)
* Environments: **Global**, **CI**, **Staging**, **Production**
* Secure **GitHub Actions OIDC → AWS IAM Roles** integration
* Modular and reusable building blocks under `modules/`

---

## 🏗 Architecture

```
GitHub Actions (OIDC)
        │
        ▼
 ┌───────────────┐
 │ AWS IAM Roles │  (ListService-Global-Deploy, ListService-CI-Deploy, etc.)
 └───────┬───────┘
         │
         ▼
 ┌─────────────────────────────────────────┐
 │   AWS Infrastructure (per environment)  │
 │ ──────────────────────────────────────  │
 │   • VPC + Networking                    │
 │   • ECS Fargate (Cluster + Service)     │
 │   • Application Load Balancer (ALB)     │
 │   • ECR (Docker registry)               │
 │   • CloudWatch Logs + Alarms            │
 │   • AutoScaling                         │
 └─────────────────────────────────────────┘
```

---

## 🌍 Environments

### **Global**

* Location: `listservice-infra/global/`
* Sets up **shared one-time resources**:

  * **ECR Repository** (`listservice-global`)
  * **OIDC Provider** for GitHub Actions
  * **IAM Roles** (`ListService-Global-Deploy`)
* Applied rarely — only when bootstrapping or changing global infra.

---

### **CI**

* Location: `listservice-infra/envs/ci/`
* **Ephemeral environment** for testing every PR & `main` branch push.
* HTTP-only ALB (no TLS in CI).
* Resources:

  * VPC + public subnets
  * ECS Fargate + ALB
  * Observability (CloudWatch alarms)

**Links**:

* Last successful run → [CI Run](https://github.com/humayun-rashid/withSecure-Assignment/actions/runs/17027999986)
* Dispatch new run → [Trigger Workflow](https://github.com/humayun-rashid/withSecure-Assignment/actions/workflows/infra-ci.yml)
* Health check → [http://listservice-ci-alb-1980907909.eu-central-1.elb.amazonaws.com/health](http://listservice-ci-alb-1980907909.eu-central-1.elb.amazonaws.com/health)
* Swagger UI → [http://listservice-ci-alb-1980907909.eu-central-1.elb.amazonaws.com/docs](http://listservice-ci-alb-1980907909.eu-central-1.elb.amazonaws.com/docs)
* ReDoc → [http://listservice-ci-alb-1980907909.eu-central-1.elb.amazonaws.com/redoc](http://listservice-ci-alb-1980907909.eu-central-1.elb.amazonaws.com/redoc)

---

### **Staging**

* Location: `listservice-infra/envs/staging/`
* Stable **pre-production** environment for UAT & integration testing
* HTTPS-enabled ALB + private subnets

---

### **Production**

* Location: `listservice-infra/envs/prod/`
* Full **production deployment**
* Separate backend state (`listservice/prod/terraform.tfstate`)
* HTTPS, scaling policies, monitoring, and hardened network

---

## 🗄 State Bootstrapping

Terraform uses **S3 (remote state) + DynamoDB (state locking)**.
Bootstrapping is handled by **`scripts/bootstrap_tf_state.sh`**.

✅ Features:

* Creates **S3 bucket** with:

  * Versioning enabled
  * SSE-S3 encryption
  * Public access blocked
  * TLS-only bucket policy
* Creates **DynamoDB lock table**
* Optionally **purges old state** safely (prefix-based delete)
* Optionally **writes `backend.hcl`** for Terraform

Example usage:

```bash
# Bootstrap CI environment backend
./scripts/bootstrap_tf_state.sh --profile sandbox --region eu-central-1 \
  --backend-out envs/ci/backend.hcl \
  --backend-key listservice/ci/terraform.tfstate
```

Resulting `backend.hcl` looks like:

```hcl
bucket         = "tf-state-<account>-eu-central-1"
key            = "listservice/ci/terraform.tfstate"
region         = "eu-central-1"
dynamodb_table = "tf-state-lock"
encrypt        = true
```

---

## 🔐 OIDC & IAM Setup

GitHub Actions uses **OpenID Connect (OIDC)** to assume AWS IAM roles.

Setup script: **`scripts/setup-oidc-role.sh`**

✅ What it does:

* Ensures **OIDC provider** exists in AWS (`token.actions.githubusercontent.com`)
* Creates/updates IAM role (e.g., `ListService-Global-Deploy`) with:

  * **Trust policy** → only `OWNER/REPO:environment` can assume role
  * **Inline policies**:

    * **Terraform State Access** → S3 bucket + DynamoDB lock table
    * **ECR Access** → push/pull container images
    * **CI Infra Access** → CloudWatch, ECS, IAM describe actions

Example run:

```bash
./scripts/setup-oidc-role.sh \
  --profile sandbox \
  --region eu-central-1 \
  --owner humayun-rashid \
  --repo withSecure-Assignment \
  --environment global \
  --role-name ListService-Global-Deploy \
  --state-prefix listservice/global/ \
  --repo-name listservice-global \
  --yes
```

Output:

```
✅ Done.
Role ARN   : arn:aws:iam::<account>:role/ListService-Global-Deploy
State S3   : s3://tf-state-<account>-eu-central-1/listservice/global/
Lock table : tf-state-lock
```

---

## 🧩 Modules

Reusable **modules/**:

* `network/` → VPC, subnets, routing tables
* `ecs/` → ECS cluster, service, task definitions
* `alb/` → Application Load Balancer + listeners
* `ecr/` → Elastic Container Registry
* `autoscaling/` → ECS task scaling policies
* `observability/` → CloudWatch logs, metrics, alarms

---

## 🛠 Scripts

Each environment (`envs/<env>/scripts/`) has helper scripts:

```bash
./plan.sh       # terraform plan
./apply.sh      # terraform apply
./output.sh     # show outputs (ALB DNS, etc.)
./destroy.sh    # terraform destroy
```

Global scripts:

* `bootstrap_tf_state.sh` → bootstraps remote state (S3 + DynamoDB)
* `setup-oidc-role.sh` → configures IAM roles & OIDC trust

---

## 🔄 Workflows

Workflows are under `.github/workflows/`:

| Workflow           | Path                                 | Env    | Purpose                             |
| ------------------ | ------------------------------------ | ------ | ----------------------------------- |
| **Infra (Global)** | `.github/workflows/infra-global.yml` | Global | Bootstraps shared infra (ECR, OIDC) |
| **Infra (CI)**     | `.github/workflows/infra-ci.yml`     | CI     | Creates ephemeral CI infra          |

* Both support `plan`, `apply`, `destroy` via **workflow dispatch**.
* Run with **OIDC → AWS IAM role** (no static creds).

---

✅ With this setup:

* **Remote state** is safely bootstrapped & locked.
* **OIDC roles** allow secure GitHub → AWS deployments.
* **CI service** is testable via `/health`, `/docs` (Swagger), `/redoc`.
* Staging & Prod follow same patterns with hardened infra.

---
