# Project Report

## Automated CI/CD Pipeline for Containerized Web Application Deployment on AWS Cloud

---

**Submitted By:** Umesh Dangi
**Course:** Bachelor of Computer Applications (BCA) — Final Year
**Academic Year:** 2025–2026

---

## Table of Contents

1. Introduction
2. Problem Statement
3. Objectives
4. Technology Stack
5. System Architecture
6. Three-Repository Strategy
7. Module Description
8. Implementation Details
9. CI/CD Pipeline Flow
10. Testing & Validation
11. Results & Screenshots
12. Advantages
13. Limitations
14. Future Enhancements
15. Conclusion
16. References

---

## 1. Introduction

Software deployment has evolved significantly over the past decade. Modern organizations no longer manually deploy applications — they rely on automated pipelines that test, build, and ship code within minutes of a developer's commit. This practice, known as **CI/CD (Continuous Integration and Continuous Deployment)**, is now a fundamental requirement in the software industry.

This project implements a **production-grade CI/CD pipeline** for a containerized web application on AWS cloud. Every component — from infrastructure provisioning to application deployment — is fully automated and version-controlled, following practices used by companies like Netflix, Amazon, and Spotify.

The application is a Python Flask web service deployed on **AWS EKS (Elastic Kubernetes Service)**, managed entirely through code using Terraform, Ansible, Jenkins, and Kubernetes — without a single manual AWS Console click after initial setup.

---

## 2. Problem Statement

In traditional software teams, deployment involves:
- Manually SSH-ing into servers and copying files
- Configuring environments by hand on every server
- No consistency between development and production environments
- High risk of human error during releases
- Hours or days of downtime during application updates
- No version control over infrastructure — "works on my machine" problem

These issues become critical as applications and teams scale.

**This project solves these problems by:**
- Automating the entire pipeline from code commit to live deployment
- Containerizing the application so it runs identically in every environment
- Managing cloud infrastructure through code — reproducible and version-controlled
- Implementing health checks and rolling updates for zero-downtime deployments
- Storing infrastructure state remotely for team collaboration
- Adding manual approval gates to prevent accidental infrastructure changes

---

## 3. Objectives

1. Build and containerize a Python Flask web application using Docker
2. Implement a Jenkins CI/CD pipeline with automated lint, build, push, and deploy stages
3. Provision AWS cloud infrastructure (VPC, EKS, ECR, EC2) using modular Terraform
4. Automate Jenkins server configuration using Ansible roles
5. Deploy the application on Kubernetes with rolling updates, health probes, and resource limits
6. Store Terraform remote state in AWS S3 for reproducibility
7. Implement GitHub webhook-based auto-triggering with manual approval gates for infrastructure
8. Send email notifications on pipeline success and failure

---

## 4. Technology Stack

| Category | Technology | Version | Purpose |
|----------|-----------|---------|---------|
| Application | Python Flask | 3.0.0 | Web application framework |
| WSGI Server | Gunicorn | 21.2.0 | Production-grade HTTP server |
| Containerization | Docker | Latest | Package app with all dependencies |
| CI/CD | Jenkins | LTS | Pipeline orchestration |
| Code Quality | flake8 | Latest | Python linting |
| Cloud Provider | AWS | — | Cloud infrastructure |
| Container Registry | AWS ECR | — | Store and version Docker images |
| Kubernetes | AWS EKS | 1.28 | Container orchestration and scaling |
| IaC | Terraform | 1.5+ | Infrastructure as Code |
| Remote State | AWS S3 | — | Terraform state management |
| Config Management | Ansible | 2.15+ | Server setup with roles |
| Version Control | Git + GitHub | — | Source code + webhook triggers |
| Manifest Management | Kustomize | — | Kubernetes manifest organization |

---

## 5. System Architecture

### Overall System Flow

```
+--------------+   push    +-----------+  webhook  +------------------+
|  Developer   | --------> |  GitHub   | --------> |  Jenkins Server  |
|  (local)     |           | (2 repos) |           |  (EC2 t2.micro)  |
+--------------+           +-----------+           +--------+---------+
                                                            |
                           +--------------------------------+
                           |
                           v
                +---------------------+
                |   Jenkins Pipeline  |
                |  1. Lint & Test     |
                |  2. Docker Build    |
                |  3. ECR Push        |
                |  4. EKS Deploy      |
                |  5. Email Notify    |
                +----------+----------+
                           |
             +-------------+-------------+
             |                           |
             v                           v
   +-----------------+        +----------------------+
   |    AWS ECR      |        |       AWS EKS        |
   | (Docker Images) |        |  Pod1  Pod2          |
   +-----------------+        |  LoadBalancer Svc    |
                              +----------+-----------+
                                         |
                                         v
                                 +---------------+
                                 |   End Users   |
                                 |   (HTTP:80)   |
                                 +---------------+
```

### AWS Infrastructure Layout

```
AWS Region: ap-south-1

Bootstrap VPC (10.10.0.0/16)          Main Infra VPC (10.0.0.0/16)
+---------------------------+          +--------------------------------------+
| Public Subnet             |          | Public Subnets (10.0.1.x, 10.0.2.x) |
| (10.10.1.0/24)            |          | └ LoadBalancer (EKS Service)         |
|                           |          | └ NAT Gateway                        |
| Jenkins EC2 (t2.micro)    |          +--------------------------------------+
| + IAM Role (Admin)        |          | Private Subnets (10.0.10.x, 10.0.11.x)|
|                           |          | └ EKS Node (t3.medium)              |
| Ansible EC2 (t2.micro)    |          | └ EKS Node (t3.medium)              |
| + Ansible pre-installed   |          +--------------------------------------+
+---------------------------+
          │  AWS APIs (HTTPS)
          └───────────────────> EKS Control Plane
                                            ECR Registry
```

---

## 6. Three-Repository Strategy

The project is split into **three** GitHub repositories following the **separation of concerns** principle:

| Repository | Contents | Deploy Trigger |
|------------|----------|----------------|
| `cloudpulse-bootstrap` | Bootstrap Terraform — Jenkins EC2, Ansible EC2, VPC | Manual (once only) |
| `cloudpulse-app` | Flask app, Dockerfile, K8s manifests, Jenkinsfile | Auto on every push |
| `cloudpulse-infra` | Terraform modules, Ansible roles, Jenkinsfile-infra | Plan auto, apply manual |

**Why three repos?**
- Bootstrap is a one-time setup concern — isolated from day-to-day work
- App changes are frequent and low-risk — safe to auto-deploy
- Infrastructure changes are rare and high-risk — require human review
- Independent access controls (dev team vs infra team)

### Bootstrap Strategy — Solving the Chicken-and-Egg Problem

A classic DevOps challenge: Jenkins needs infrastructure to exist, but we want Terraform to manage that infrastructure. Solved with a 3-phase approach:

```
Phase 1 — cloudpulse-bootstrap (run locally, once)
  Creates:
  ├─ Bootstrap VPC (10.10.0.0/16) — completely isolated from main infra VPC
  ├─ Jenkins EC2 (t2.micro) + IAM Role (AdministratorAccess)
  └─ Ansible EC2 (t2.micro) + Ansible pre-installed via user_data

Phase 2 — Ansible (run from Ansible server, once)
  Configures Jenkins via 4 roles:
  java → docker → jenkins → aws-tools

Phase 3 — Jenkins pipelines (all future work automated)
  cloudpulse-infra pipeline → manages main VPC, EKS, ECR
  cloudpulse-app pipeline  → handles all app deployments
```

**Two VPCs = Full Isolation:**
- Bootstrap VPC `10.10.0.0/16` — Jenkins + Ansible
- Main Infra VPC `10.0.0.0/16` — EKS nodes (private subnets) + LoadBalancer (public subnets)
- Jenkins communicates with EKS via AWS public APIs (HTTPS) — no VPC peering needed

---

## 7. Module Description

### 7.1 Application Module (app/)

| File | Description |
|------|-------------|
| main.py | Flask app — `/` returns app info, `/health` returns JSON for K8s probes |
| Dockerfile | Python 3.11-slim, Gunicorn 2 workers, HEALTHCHECK, no-cache pip install |
| requirements.txt | Flask 3.0.0 + Gunicorn 21.2.0 |
| .dockerignore | Excludes pycache, logs, .env from Docker build context |

### 7.2 CI/CD Pipeline Module (jenkins/Jenkinsfile)

| Stage | Tool | What Happens |
|-------|------|-------------|
| Lint & Test | flake8, Python | Code quality check + app smoke test |
| Build | Docker | Image built tagged with Jenkins build number |
| Push | AWS ECR | Image authenticated and pushed to registry |
| Deploy | kubectl | Rolling update triggered + rollout verification |
| Notify | Gmail SMTP | Email sent on success or failure |

### 7.3 Infrastructure Modules

**cloudpulse-bootstrap** (one-time setup):

| Module | AWS Resources Created |
|--------|----------------------|
| modules/vpc | Bootstrap VPC (10.10.0.0/16), public subnet, IGW, route table |
| modules/jenkins | EC2 t2.micro, Security Group (22, 8080), IAM Role (AdministratorAccess) |
| modules/ansible | EC2 t2.micro, Security Group (22), Ansible via user_data |

**cloudpulse-infra** (managed by Jenkins pipeline):

| Module | AWS Resources Created |
|--------|----------------------|
| modules/vpc | VPC (10.0.0.0/16), 2 public + 2 private subnets, IGW, NAT Gateway |
| modules/eks | EKS Cluster, Node Group on private subnets (t3.medium x2), IAM Roles |
| modules/ecr | ECR Docker image repository |

All variables parameterized via `.tfvars` — override without changing code.

### 7.4 Configuration Management Module (ansible/)

Ansible roles — each role has `tasks/main.yml` and `defaults/main.yml` with variables:

| Role | Installs | Key Variable |
|------|---------|-------------|
| java | Amazon Corretto 17 | `java_package` |
| docker | Docker, starts service | `docker_package` |
| jenkins | Jenkins, adds to docker group | `jenkins_repo_url` |
| aws-tools | AWS CLI v2, kubectl v1.28 | `kubectl_version` |

`group_vars/jenkins.yml` holds host-level overrides.

### 7.5 Kubernetes Module (k8s/)

| File | Purpose |
|------|---------|
| namespace.yaml | Isolated `cloudpulse` namespace with labels |
| deployment.yaml | 2 replicas, RollingUpdate, liveness + readiness probes, CPU/memory limits |
| service.yaml | LoadBalancer — exposes app externally on port 80 |
| kustomization.yaml | Single command: `kubectl apply -k k8s/` |

### 7.6 Infrastructure Pipeline (jenkins/Jenkinsfile-infra)

| ACTION | Approval | Behavior |
|--------|----------|----------|
| plan | Not required | Shows planned changes — safe, informational |
| apply | Required | Creates or updates infrastructure |
| destroy | Required | Deletes all infrastructure |

Auto-triggers on git push and runs plan. Apply and destroy always require manual approval.

---

## 8. Implementation Details

### 8.1 Flask Application

```
Endpoints:
  GET /        -> "Hello from CloudPulse! Version X.X"  (version from K8s env var)
  GET /health  -> {"status": "healthy"}               (used by K8s probes)
```

### 8.2 Docker Best Practices Applied

- `python:3.11-slim` base image — ~50MB vs ~900MB for full Python image
- `--no-cache-dir` — removes pip cache from the image layer, reduces size
- `HEALTHCHECK` instruction — Docker-level health monitoring
- `--workers 2` — Gunicorn handles concurrent requests in production
- `.dockerignore` — prevents unnecessary files entering build context

### 8.3 Terraform Modular Design

Root `main.tf` wires modules together using outputs as inputs:

```hcl
module "eks" {
  source     = "./modules/eks"
  subnet_ids = module.vpc.subnet_ids  # VPC output -> EKS input
  vpc_id     = module.vpc.vpc_id
}
```

Two separate S3 state keys prevent state conflicts between bootstrap and main infra:
- `bootstrap/terraform.tfstate` — Jenkins EC2
- `infra/terraform.tfstate` — VPC, EKS, ECR

### 8.4 Kubernetes Zero-Downtime Deployment

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1         # 1 extra pod created during update
    maxUnavailable: 0   # 0 pods removed until new one is Ready
```

Result: At no point during deployment is the application unavailable to users.

---

## 9. CI/CD Pipeline Flow

### App Pipeline (cloudpulse-app)

```
git push
  |
  v
GitHub Webhook --> Jenkins auto-trigger
  |
  +-- Stage 1: Lint & Test
  |     flake8 main.py --max-line-length=120
  |     python -c "import main"   (smoke test)
  |
  +-- Stage 2: Docker Build
  |     docker build -t <ECR_URL>:<BUILD_NUMBER> .
  |
  +-- Stage 3: Push to ECR
  |     aws ecr get-login-password | docker login
  |     docker push <ECR_URL>:<BUILD_NUMBER>
  |
  +-- Stage 4: Deploy to EKS
  |     aws eks update-kubeconfig --name cloudpulse-cluster
  |     kubectl set image deployment/cloudpulse-app ...
  |     kubectl rollout status --timeout=60s
  |
  +-- Post: Email (success or failure)
```

### Infrastructure Pipeline (cloudpulse-infra)

```
git push
  |
  v
Auto-trigger: Init --> fmt check --> validate --> Plan
  |
  v
[PAUSE] Manual Approval ("Yes, Proceed")
  |
  +-- apply   --> terraform apply tfplan --> Email
  +-- destroy --> terraform destroy      --> Email
```

---

## 10. Testing & Validation

| Test | Tool | Stage | Purpose |
|------|------|-------|---------|
| Python linting | flake8 | Pre-build | Catch style errors and unused imports |
| App smoke test | Python import | Pre-build | Verify app loads without runtime errors |
| Terraform formatting | terraform fmt -check | Infra pipeline | Enforce consistent HCL style |
| Terraform syntax | terraform validate | Infra pipeline | Catch config errors before apply |
| K8s rollout check | kubectl rollout status | Post-deploy | Confirm all pods healthy after deploy |
| Liveness probe | HTTP GET /health | Runtime (K8s) | Auto-restart unhealthy pods |
| Readiness probe | HTTP GET /health | Runtime (K8s) | Block traffic until pod is ready |
| Docker HEALTHCHECK | curl /health | Runtime (Docker) | Container-level health monitoring |

---

## 11. Results & Screenshots

*(Add screenshots after deployment)*

Screenshots to include:
1. Jenkins pipeline — all stages green
2. AWS EKS console — cluster and nodes in Ready state
3. `kubectl get pods -n cloudpulse` — 2 pods Running
4. Application live at LoadBalancer URL — showing version
5. Gmail inbox — deployment success notification
6. Code version change pushed — rolling update in progress — new version live

---

## 12. Advantages

| Advantage | Description |
|-----------|-------------|
| Full Automation | Code push to live deployment with zero manual steps |
| Consistency | Docker ensures identical behavior across all environments |
| Zero Downtime | Kubernetes RollingUpdate — no service interruption during deploys |
| Infrastructure as Code | Entire AWS setup in version-controlled, reproducible Terraform |
| Separation of Concerns | App and infra in separate repos — independent teams and deploy cycles |
| Safety Gates | Manual approval before infra apply/destroy — prevents accidents |
| Observability | Health probes + email notifications — visibility into system state |
| Idempotent Infra | `terraform apply` is safe to run repeatedly — only changes are applied |
| Modular Design | Terraform modules + Ansible roles — reusable and maintainable components |
| Resource Control | K8s CPU/memory limits — prevents any pod from exhausting node resources |

---

## 13. Limitations

1. **No HTTPS** — LoadBalancer serves HTTP; SSL/TLS certificate not configured
2. **Single Region** — No disaster recovery across AWS regions
3. **No Monitoring Dashboard** — No Prometheus/Grafana for real-time metrics
4. **No HTTPS** — LoadBalancer serves HTTP; SSL/TLS certificate not configured
5. **No Staging Environment** — Deploys directly to production cluster
6. **Stateless Application** — No database; no persistent data layer

---

## 14. Future Enhancements

| Enhancement | Benefit |
|-------------|---------|
| HTTPS with AWS ACM + ALB Ingress | Encrypted, secure communication |
| Private subnets + NAT Gateway | Production-grade network security |
| Prometheus + Grafana | Real-time metrics, dashboards, and alerting |
| Helm Charts | Versioned, templated Kubernetes deployments |
| Staging environment | Validate changes before production |
| ArgoCD (GitOps) | Git as single source of truth for K8s state |
| Horizontal Pod Autoscaler | Auto-scale pods based on CPU/memory load |
| Terraform DynamoDB lock | Prevent concurrent state file corruption |
| Multi-region active-active | High availability and disaster recovery |

---

## 15. Conclusion

This project successfully implements an end-to-end DevOps pipeline covering the complete software delivery lifecycle — from a developer's code commit to a live, scalable application running on AWS Kubernetes.

Key achievements:

- A single `git push` automatically triggers code linting, Docker image building, container registry push, and Kubernetes deployment — with email confirmation — completely without human intervention
- The complete AWS infrastructure (VPC, EKS cluster, ECR registry, Jenkins EC2) is defined as modular, version-controlled Terraform code — fully reproducible from scratch in minutes
- Jenkins server configuration is automated using Ansible roles — no manual server steps required
- Kubernetes deployment follows production best practices: rolling updates for zero downtime, health probes for self-healing, resource limits for stability, and namespace isolation
- Infrastructure changes require mandatory manual approval — safety without sacrificing automation

This project demonstrates not just familiarity with individual DevOps tools, but understanding of how they integrate into a cohesive, automated, and safe delivery pipeline — reflecting real-world engineering practices at scale.

---

## 16. References

1. Jenkins Documentation — https://www.jenkins.io/doc/
2. Terraform AWS Provider — https://registry.terraform.io/providers/hashicorp/aws/
3. Kubernetes Documentation — https://kubernetes.io/docs/
4. Docker Official Documentation — https://docs.docker.com/
5. AWS EKS User Guide — https://docs.aws.amazon.com/eks/latest/userguide/
6. AWS ECR User Guide — https://docs.aws.amazon.com/AmazonECR/latest/userguide/
7. Ansible Documentation — https://docs.ansible.com/
8. Flask Documentation — https://flask.palletsprojects.com/
9. Gunicorn Documentation — https://gunicorn.org/
10. Kustomize Documentation — https://kustomize.io/

