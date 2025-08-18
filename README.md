
---

# 📦 ListService – Serverless Application

[![Build, Publish, Deploy & Test](https://github.com/humayun-rashid/withSecure-Assignment/actions/workflows/build-publish-deploy-test.yml/badge.svg)](https://github.com/humayun-rashid/withSecure-Assignment/actions/workflows/build-publish-deploy-test.yml)
[![Infra CI](https://github.com/humayun-rashid/withSecure-Assignment/actions/workflows/infra-ci.yml/badge.svg)](https://github.com/humayun-rashid/withSecure-Assignment/actions/workflows/infra-ci.yml)
[![Health](https://img.shields.io/website?url=http%3A%2F%2Flistservice-ci-alb-1980907909.eu-central-1.elb.amazonaws.com%2Fhealth\&label=API%20Health)](http://listservice-ci-alb-1980907909.eu-central-1.elb.amazonaws.com/health)
[![Docs](https://img.shields.io/badge/docs-Swagger-blue)](http://listservice-ci-alb-1980907909.eu-central-1.elb.amazonaws.com/docs)
[![ReDoc](https://img.shields.io/badge/docs-ReDoc-orange)](http://listservice-ci-alb-1980907909.eu-central-1.elb.amazonaws.com/redoc)

The **ListService** project is a serverless application deployed on **AWS**, built with **FastAPI**, **Docker**, **Terraform**, and **GitHub Actions**.
It demonstrates cloud-native backend design, infrastructure as code, and CI/CD automation.

📚 For full detailed design, implementation, and usage guides:

* 👉 [Backend Documentation](listservice-backend/README.md)
* 👉 [Infrastructure Documentation](infrastructure/README.md)

---

## 📑 Table of Contents

1. [Overview](#-overview)

   1. [Backend (FastAPI Service)](#-backend-fastapi-service)
   2. [Infrastructure (Terraform)](#️-infrastructure-terraform)
   3. [CI/CD Workflows](#️-cicd-workflows)
2. [High-Level Architecture](#-high-level-architecture)
3. [Documentation](#-documentation)
4. [Tech Stack](#-tech-stack)

---

## 🚀 Overview

### ✅ Backend (FastAPI Service)

* Lightweight **Python FastAPI** service providing REST APIs for list operations:

  * `head` → first *N* items
  * `tail` → last *N* items
* Fully **dockerized** and tested with **local smoke-test scripts**.
* CI/CD ensures images are built, pushed, deployed, and validated automatically.
* Built-in API docs:

  * Swagger UI → `http://<ALB_DNS>/docs`
  * ReDoc → `http://<ALB_DNS>/redoc`

👉 [Backend Documentation](listservice-backend/README.md)

#### 🔗 Live CI Environment (AWS ECS Fargate, eu-central-1)

* **Health check** → [http://listservice-ci-alb-1980907909.eu-central-1.elb.amazonaws.com/health](http://listservice-ci-alb-1980907909.eu-central-1.elb.amazonaws.com/health)
* **Swagger UI** → [http://listservice-ci-alb-1980907909.eu-central-1.elb.amazonaws.com/docs](http://listservice-ci-alb-1980907909.eu-central-1.elb.amazonaws.com/docs)
* **ReDoc** → [http://listservice-ci-alb-1980907909.eu-central-1.elb.amazonaws.com/redoc](http://listservice-ci-alb-1980907909.eu-central-1.elb.amazonaws.com/redoc)

---

### ☁️ Infrastructure (Terraform)

* Defined entirely in **Terraform**, structured for **multi-environment deployment**:

  * **CI**, **Staging**, **Production**
* Modular design:

  * **ECR** (image registry)
  * **ECS Fargate** (containers)
  * **ALB** (public entrypoint)
  * **Networking** (VPC, subnets, security groups)
  * **Autoscaling & Observability** (CloudWatch metrics, logs, alarms)

```
listservice-infra/
├── envs/ci, staging, prod   # Environment configs
├── modules/                 # Reusable Terraform modules
│   ├── ecs / alb / network / ecr / autoscaling / observability
└── scripts/                 # Plan, apply, destroy, smoke-test
```

👉 [Infrastructure Documentation](infrastructure/README.md)
👉 [Infra CI Workflow](https://github.com/humayun-rashid/withSecure-Assignment/actions/workflows/infra-ci.yml)

---

### ⚙️ CI/CD Workflows

We use **GitHub Actions** for both application delivery and infrastructure management.

#### 🟦 Application Workflow

* **[Build, Publish, Deploy & Test (ECS)](.github/workflows/build-publish-deploy-test.yml)**
  A single pipeline that:

  1. **Builds & pushes** the Docker image to ECR (tags: SHA, `ci`, `latest`, branch).
  2. **Deploys** to ECS Fargate (`listservice-ci-svc`).
  3. **Waits** for ECS service to stabilize.
  4. **Discovers** the ALB DNS dynamically.
  5. **Runs API tests** (`/health`, `/head`, `/tail` GET + POST).
  6. **Fails fast** if any step breaks.

ASCII job timeline:

```
 build-and-push ──► deploy ──► test
```

🔗 **Last Run:** [#17028246479](https://github.com/humayun-rashid/withSecure-Assignment/actions/runs/17028246479)

---

#### 🟩 Infrastructure Workflows

* **[Infra (CI)](.github/workflows/infra-ci.yml)**
  Manages **CI environment infrastructure** (`envs/ci/`) with Terraform.

  * Triggers on changes to CI env code.
  * Supports `plan`, `apply`, `destroy`.
  * Smoke tests `/health` after apply.

  🔗 [Workflow Page](https://github.com/humayun-rashid/withSecure-Assignment/actions/workflows/infra-ci.yml)

* **[Infra (GLOBAL)](.github/workflows/infra-global.yml)**
  Manages **global/shared infrastructure** (e.g., ECR repos, IAM roles, networking).

  * Supports `plan`, `apply`, `destroy`.
  * Uploads plan artifacts on PRs.

---

## 🔮 High-Level Architecture

```
               +-------------------+
               |   Developer       |
               |   (GitHub Push)   |
               +---------+---------+
                         |
                         v
                +-------------------+
                | GitHub Actions    |
                |  CI/CD Pipelines  |
                +----+---------+----+
                     |         |
     Build & Push    |         |  Deploy
   (Docker → ECR)    |         |  (ECS Fargate)
                     |         |
                     v         v
         +-------------------+   +-------------------+
         |   Amazon ECR      |   |   Amazon ECS      |
         |  (Image Registry) |   |  (Serverless App) |
         +---------+---------+   +---------+---------+
                                   |
                                   v
                          +-------------------+
                          | Application Load  |
                          | Balancer (ALB)    |
                          +---------+---------+
                                    |
                                    v
                           +-------------------+
                           |  ListService API  |
                           |  (FastAPI)        |
                           +-------------------+
```

---

## 📚 Documentation

* [Backend Documentation](listservice-backend/README.md)
* [Infrastructure Documentation](infrastructure/README.md)
* [Build, Publish, Deploy & Test Workflow](.github/workflows/build-publish-deploy-test.yml)
* [Infra CI Workflow](.github/workflows/infra-ci.yml)
* [Infra GLOBAL Workflow](.github/workflows/infra-global.yml)

---

## 🛠 Tech Stack

* **Application** → FastAPI (Python)
* **Containerization** → Docker
* **Cloud Platform** → AWS ECS Fargate, ECR, ALB, VPC, IAM
* **Infrastructure as Code** → Terraform (multi-env, modular)
* **CI/CD** → GitHub Actions (Build → Publish → Deploy → Test)

---

