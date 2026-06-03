# Synopsis

## Automated CI/CD Pipeline for Containerized Application Deployment on AWS

---

### 1. Project Title
**Automated CI/CD Pipeline for Containerized Application Deployment on AWS**

---

### 2. Student Details
- **Name:** Umesh Dangi
- **Course:** BCA (Bachelor of Computer Applications)
- **Year:** Final Year

---

### 3. Introduction
DevOps is a set of practices that combines software development and IT operations to shorten the development lifecycle and deliver high-quality software continuously. This project implements a fully automated CI/CD (Continuous Integration / Continuous Deployment) pipeline that builds, tests, and deploys a containerized web application on AWS cloud using Kubernetes.

---

### 4. Objective
To design and implement an automated deployment pipeline that:
- Builds and tests application code automatically on every code push
- Packages the application in Docker containers
- Provisions cloud infrastructure using code (Terraform)
- Deploys containers on Kubernetes cluster (AWS EKS)
- Sends notifications on deployment status

---

### 5. Scope
- Development of a Python Flask web application
- Dockerization of the application
- Bootstrap infrastructure (Jenkins + Ansible EC2) via separate Terraform repo
- Setting up Jenkins CI/CD server using Ansible roles (from Ansible server)
- Creating AWS infrastructure (VPC with private/public subnets, EKS, ECR) with Terraform
- Automated deployment pipeline with linting and testing
- Email notifications for build status
- Three-repository strategy: `cloudpulse-bootstrap`, `cloudpulse-app`, `cloudpulse-infra`

---

### 6. Tools & Technologies

| Tool | Version | Purpose |
|------|---------|---------|
| Python | 3.11 | Application development |
| Flask | 3.0.0 | Web framework |
| Docker | Latest | Containerization |
| Jenkins | LTS | CI/CD automation |
| Terraform | 1.5+ | Infrastructure as Code |
| Ansible | 2.15+ | Configuration management |
| Kubernetes | 1.28 | Container orchestration |
| AWS EKS | - | Managed Kubernetes |
| AWS ECR | - | Container registry |
| Git/GitHub | - | Version control |

---

### 7. Methodology

**Phase 1:** Application Development
- Develop Flask REST API
- Write Dockerfile
- Test locally

**Phase 2:** Infrastructure Setup
- Write cloudpulse-bootstrap Terraform (Jenkins EC2 + Ansible EC2 + Bootstrap VPC)
- Write cloudpulse-infra Terraform modules (VPC with private subnets, EKS, ECR)
- Provision AWS resources via Jenkins pipeline
- Configure Jenkins server via Ansible (run from Ansible server)

**Phase 3:** Pipeline Development
- Create Jenkins CI/CD pipeline
- Add lint & test stages
- Configure ECR push and EKS deploy
- Add email notifications

**Phase 4:** Testing & Deployment
- End-to-end pipeline testing
- Verify auto-deployment on git push
- Validate rollback capability

---

### 8. Expected Outcome
A fully functional automated pipeline where:
1. Developer pushes code to GitHub
2. Jenkins automatically triggers pipeline
3. Code is linted and tested
4. Docker image is built and pushed to ECR
5. Application is deployed to EKS cluster
6. Email notification is sent with build status

---

### 9. Hardware & Software Requirements

**Hardware:**
- Development machine (any OS with 4GB+ RAM)
- AWS EC2 t2.micro x2 (Jenkins server + Ansible server — bootstrap VPC)
- AWS EKS cluster (2 t3.medium nodes — main infra VPC, private subnets)

**Software:**
- VS Code (IDE)
- Git
- Docker Desktop
- AWS CLI
- Terraform CLI
- Ansible

---

### 10. Timeline

| Week | Activity |
|------|----------|
| 1 | Application development & Dockerization |
| 2 | Terraform infrastructure code |
| 3 | Jenkins setup with Ansible |
| 4 | CI/CD pipeline development |
| 5 | Testing & bug fixes |
| 6 | Documentation & report writing |

---

### 11. References
1. Jenkins Documentation — https://www.jenkins.io/doc/
2. Terraform AWS Provider — https://registry.terraform.io/providers/hashicorp/aws/
3. Kubernetes Documentation — https://kubernetes.io/docs/
4. AWS EKS Documentation — https://docs.aws.amazon.com/eks/
