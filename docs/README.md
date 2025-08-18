Got it 👍 — let’s make the root **README.md** truly **drop-ready for GitHub**, with:

* **ASCII diagram** (instead of Mermaid, so it renders everywhere).
* **Links to each workflow file** for transparency.
* **A reference to the last executed run URL** so readers can directly see pipeline execution.

Here’s the polished version 👇

---

# 📦 ListService – Serverless Application

The **ListService** project is a serverless application deployed on **AWS**, built with **FastAPI**, **Docker**, **Terraform**, and **GitHub Actions**.
It demonstrates cloud-native backend design, infrastructure as code, and CI/CD automation.

---

## 📑 Table of Contents

1. [Overview](#-overview)

   1. [Backend (FastAPI Service)](#-backend-fastapi-service)
   2. [Infrastructure (Terraform)](#%EF%B8%8F-infrastructure-terraform)
   3. [CI/CD Workflows](#%EF%B8%8F-cicd-workflows)
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

👉 [Infrastructure Documentation](listservice-infra/README.md)

---

### ⚙️ CI/CD Workflows

The project uses **GitHub Actions** with three core workflows:

* **[Build & Publish (ECR)](.github/workflows/build-publish.yml)** → builds and pushes Docker images
* **[Deploy to ECS (CI)](.github/workflows/deploy-ecs.yml)** → deploys the latest image to ECS Fargate
* **[Build, Publish, Deploy & Test (ECS)](.github/workflows/build-publish-deploy-test.yml)** → end-to-end build, deploy, and API test pipeline

🔗 **Last executed workflow run:**
[View on GitHub Actions](https://github.com/humayun-rashid/withSecure-Assignment/actions/runs/XXXXXXXX)
*(replace `XXXXXXXX` with the latest run ID)*

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
* [Infrastructure Documentation](listservice-infra/README.md)

---

## 🛠 Tech Stack

* **Application** → FastAPI (Python)
* **Containerization** → Docker
* **Cloud Platform** → AWS ECS Fargate, ECR, ALB, VPC, IAM
* **Infrastructure as Code** → Terraform (multi-env, modular)
* **CI/CD** → GitHub Actions (Build → Publish → Deploy → Test)

---

✨ Built with **FastAPI, Docker, Terraform, AWS ECS (Fargate), and GitHub Actions** ✨

---

Do you want me to also **embed the actual last run ID URL dynamically** (instead of you replacing it manually), by showing you how to fetch it from GitHub Actions API and auto-update the README?
