
---

# 📋 ListService Backend API

## 🌍 Live CI Environment (AWS ECS Fargate, eu-central-1)

* **Health check** →
  [http://listservice-ci-alb-1980907909.eu-central-1.elb.amazonaws.com/health](http://listservice-ci-alb-1980907909.eu-central-1.elb.amazonaws.com/health)

* **Swagger UI** →
  [http://listservice-ci-alb-1980907909.eu-central-1.elb.amazonaws.com/docs](http://listservice-ci-alb-1980907909.eu-central-1.elb.amazonaws.com/docs)

* **ReDoc** →
  [http://listservice-ci-alb-1980907909.eu-central-1.elb.amazonaws.com/redoc](http://listservice-ci-alb-1980907909.eu-central-1.elb.amazonaws.com/redoc)

Use these links to verify that deployments are working in the CI environment.

---

## 📘 Overview

ListService is a **FastAPI-based microservice** for **list operations**:

* **Head** → return the first `N` items
* **Tail** → return the last `N` items

### Architecture Highlights

* **Business logic** → pure functions (`service.py`)
* **Controllers** → orchestration layer (no HTTP concerns)
* **Routes** → FastAPI endpoints with cache semantics
* **Schema models** → Pydantic v2 for request/response validation
* **Deployment** → Docker → AWS ECR → ECS Fargate behind an ALB
* **CI/CD** → GitHub Actions builds, publishes, deploys & tests

---

## ⚡ API Endpoints

### Health

`GET /health`
Returns service status:

```json
{"status": "ok"}
```

---

### List Operations

#### **Head (first N items)**

* **GET** `/v1/lists/head?list=foo,bar,baz&count=2` →

  ```json
  {"result":["foo","bar"]}
  ```

* **POST** `/v1/lists/head` →

  ```json
  {"list":["one","two","three"], "count": 2}
  ```

  Response:

  ```json
  {"result":["one","two"]}
  ```

#### **Tail (last N items)**

* **GET** `/v1/lists/tail?list=foo,bar,baz&count=1` →

  ```json
  {"result":["baz"]}
  ```

* **POST** `/v1/lists/tail` →

  ```json
  {"list":["one","two","three"], "count": 1}
  ```

  Response:

  ```json
  {"result":["three"]}
  ```

---

### Validation & Errors

* `count < 0` → error
* `count > list length` → error
* non-string list items → error

Response format:

```json
{"error": "message"}
```

---

### Caching

* **GET endpoints** → Cacheable (`ETag`, `Cache-Control`)
* **POST endpoints** → Not cacheable

---

## 🛠️ Local Development

### 1. Run with Uvicorn

```bash
pip install -r requirements.txt
uvicorn listservice.main:app --reload --port 8080
```

* Health → [http://localhost:8080/health](http://localhost:8080/health)
* Swagger → [http://localhost:8080/docs](http://localhost:8080/docs)
* ReDoc → [http://localhost:8080/redoc](http://localhost:8080/redoc)

---

### 2. Run with Docker (using scripts)

Helper scripts in `scripts/` simplify Docker workflow.

```bash
# Build the Docker image
./scripts/build.sh

# Run the container (exposes :8080)
./scripts/deploy.sh

# Test the running container
./test/smoke-test.sh

# Stop & clean up
./scripts/destroy.sh
```

The container uses **Gunicorn + Uvicorn workers** in production mode.

---

## ✅ Testing

### Local Tests

* `./test/test_local.sh` → run API locally with uvicorn & verify endpoints
* `./test/smoke-test.sh` → test against a running Docker container

### CI Tests (GitHub Actions)

* Runs full end-to-end tests against the deployed service on ECS:

  * `/health`
  * `/v1/lists/head` (GET + POST)
  * `/v1/lists/tail` (GET + POST)

Any failure blocks the pipeline.

---

## 🔄 GitHub Actions Workflows

We use **multi-stage workflows** in `.github/workflows/`.

### ASCII Workflow Diagram

```
 ┌─────────────┐       ┌─────────────┐       ┌─────────────┐
 │   Git Push  │──────▶│   Build &   │──────▶│   Deploy to │
 │ (main/ci/   │       │   Publish   │       │   ECS Farg. │
 │ staging/*)  │       │   (ECR)     │       │   (via ALB) │
 └─────────────┘       └─────────────┘       └──────┬──────┘
                                                     │
                                                     ▼
                                             ┌─────────────┐
                                             │   Test API  │
                                             │ /health     │
                                             │ /lists/*    │
                                             └─────────────┘
```

---

### 1. **Build, Publish, Deploy & Test (ECS)**

Triggered on push to `main`, `ci`, `staging`, or feature branches.
Steps:

1. **Build & Push** Docker image to ECR (`sha`, `ci`, `latest`, branch tag)
2. **Deploy** to ECS Fargate service (`listservice-ci-svc`)
3. **Discover ALB DNS** dynamically
4. **Run Tests** against live service

✅ Ensures every commit results in a deployable & testable environment.

---

### 2. **Deploy to ECS (CI – latest)**

Triggered on:

* Success of Build workflow (`workflow_run`), or
* Manual dispatch

Steps:

1. Ensures latest image (`ci` or `latest`) exists in ECR
2. Forces ECS service redeployment
3. Optionally smoke tests `/health`

✅ Provides controlled redeployment separate from build.

---

### 3. **Local Test Scripts**

Located in `/test`:

* `test_local.sh` → spins up uvicorn, verifies endpoints
* `smoke-test.sh` → tests running Docker/ALB service

---

## 🚀 Deployment Guarantees

* Every commit to `ci` environment → auto build → push → deploy → test
* ECS service always runs latest passing image
* Failures in build, push, deploy, or test stop the pipeline
* ALB DNS automatically discovered → service reachable & testable

---

## 📂 Repo Structure

```
listservice-backend/
├── Dockerfile            # Container definition
├── requirements.txt      # Python dependencies
├── scripts/              # Helper scripts for build/deploy/test
├── src/listservice/      # FastAPI app, routes, controllers, service
├── test/                 # Local + smoke test scripts
```

---

## 🧩 Tech Stack

* **Python 3.12**
* **FastAPI + Pydantic v2**
* **Gunicorn + Uvicorn workers**
* **Docker + AWS ECS Fargate + ALB**
* **GitHub Actions (OIDC → AWS IAM Roles)**

---

