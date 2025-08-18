
---

# 📦 ListService – Serverless Application

[![Build, Publish, Deploy & Test](https://github.com/humayun-rashid/withSecure-Assignment/actions/workflows/build-publish-deploy-test.yml/badge.svg)](https://github.com/humayun-rashid/withSecure-Assignment/actions/workflows/build-publish-deploy-test.yml)
[![Infra CI](https://github.com/humayun-rashid/withSecure-Assignment/actions/workflows/infra-ci.yml/badge.svg)](https://github.com/humayun-rashid/withSecure-Assignment/actions/workflows/infra-ci.yml)
[![Health](https://img.shields.io/website?url=http%3A%2F%2Flistservice-ci-alb-1980907909.eu-central-1.elb.amazonaws.com%2Fhealth\&label=API%20Health)](http://listservice-ci-alb-1980907909.eu-central-1.elb.amazonaws.com/health)
[![Docs](https://img.shields.io/badge/docs-Swagger-blue)](http://listservice-ci-alb-1980907909.eu-central-1.elb.amazonaws.com/docs)
[![ReDoc](https://img.shields.io/badge/docs-ReDoc-orange)](http://listservice-ci-alb-1980907909.eu-central-1.elb.amazonaws.com/redoc)

The **ListService** project is a serverless application deployed on **AWS**, built with **FastAPI**, **Docker**, **Terraform**, and **GitHub Actions**.
It demonstrates cloud-native backend design, infrastructure as code, and CI/CD automation.

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

* **Health check** →
  [http://listservice-ci-alb-1980907909.eu-central-1.elb.amazonaws.com/health](http://listservice-ci-alb-1980907909.eu-central-1.elb.amazonaws.com/health)

* **Swagger UI** →
  [http://listservice-ci-alb-1980907909.eu-central-1.elb.amazonaws.com/docs](http://listservice-ci-alb-1980907909.eu-central-1.elb.amazonaws.com/docs)

* **ReDoc** →
  [http://listservice-ci-alb-1980907909.eu-central-1.elb.amazonaws.com/redoc](http://listservice-ci-alb-1980907909.eu-central-1.elb.amazonaws.com/redoc)

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

The project uses **GitHub Actions** with three core workflows:

* **[Build & Publish (ECR)](.github/workflows/build-publish.yml)** → builds and pushes Docker images
* **[Deploy to ECS (CI)](.github/workflows/deploy-ecs.yml)** → deploys the latest image to ECS Fargate
* **[Build, Publish, Deploy & Test (ECS)](.github/workflows/build-publish-deploy-test.yml)** → end-to-end build, deploy, and API test pipeline

#### 🔗 Last Workflow Runs

* **Last Build, Publish, Deploy & Test:**
  [GitHub Actions Run #17028246479](https://github.com/humayun-rashid/withSecure-Assignment/actions/runs/17028246479)

* **Last Infra CI Run:**
  [Infra CI Workflow](https://github.com/humayun-rashid/withSecure-Assignment/actions/workflows/infra-ci.yml)

---

## 🔮 High-Level Architecture

Here’s the end-to-end architecture (ASCII diagram):

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
* [Build & Publish Workflow](.github/workflows/build-publish.yml)
* [Deploy ECS Workflow](.github/workflows/deploy-ecs.yml)
* [Build, Publish, Deploy & Test Workflow](.github/workflows/build-publish-deploy-test.yml)
* [Infra CI Workflow](https://github.com/humayun-rashid/withSecure-Assignment/actions/workflows/infra-ci.yml)

---

## 🛠 Tech Stack

* **Application** → FastAPI (Python)
* **Containerization** → Docker
* **Cloud Platform** → AWS ECS Fargate, ECR, ALB, VPC, IAM
* **Infrastructure as Code** → Terraform (multi-env, modular)
* **CI/CD** → GitHub Actions (Build → Publish → Deploy → Test)

---


