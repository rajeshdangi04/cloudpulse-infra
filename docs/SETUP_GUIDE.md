# Setup Guide

> For exact copy-paste commands step by step, see **RUNBOOK.md**

---

## Overview

Ye project **3 GitHub repos** mein split hai:

| Repo | Contents |
|------|----------|
| `cloudpulse-bootstrap` | Bootstrap Terraform — Jenkins + Ansible EC2 + VPC |
| `cloudpulse-app` | Flask app, Dockerfile, K8s manifests, Jenkinsfile |
| `cloudpulse-infra` | Terraform modules (VPC/EKS/ECR), Ansible roles, Jenkinsfile-infra |

---

## Prerequisites

Install on local machine:
```bash
# Windows: download installers from official sites
# Terraform, AWS CLI, kubectl, Git
# Ansible locally chahiye nahi — Ansible server AWS pe banta hai
```

AWS me chahiye:
- IAM user with AdministratorAccess
- EC2 Key Pair (`.pem` file)
- S3 bucket for Terraform state: `cloudpulse-terraform-state`

---

## Deployment Phases

### Phase 1 — Bootstrap (Separate Repo → Jenkins + Ansible EC2)
```bash
cd cloudpulse-bootstrap/
cp terraform.tfvars.example terraform.tfvars
# key_name = "cloudpulse-key" fill karo
terraform init && terraform apply
# Output: jenkins_public_ip, ansible_public_ip
# Jenkins EC2 pe IAM Role auto-attached (AdministratorAccess)
# Bootstrap VPC (10.10.0.0/16) banta hai — main infra VPC se alag
```

### Phase 2 — Configure Jenkins (Ansible Server se)
```bash
# SSH key Ansible server pe copy karo:
scp -i cloudpulse-key.pem cloudpulse-key.pem ec2-user@<ANSIBLE_IP>:~/.ssh/cloudpulse-key.pem

# Ansible server pe SSH karo:
ssh -i cloudpulse-key.pem ec2-user@<ANSIBLE_IP>

# cloudpulse-infra clone karo:
git clone https://github.com/<username>/cloudpulse-infra.git infra
cd infra/ansible
sed -i 's/<JENKINS_EC2_IP>/<JENKINS_IP>/' inventory.ini

# Connection test + playbook run:
ansible jenkins -i inventory.ini -m ping
ansible-playbook -i inventory.ini setup-jenkins.yml
```

Ansible 4 roles run karta hai in order:
1. `java` — Java 17 (Amazon Corretto) install
2. `docker` — Docker install + start
3. `jenkins` — Jenkins install, docker group add, start
4. `aws-tools` — AWS CLI + kubectl install

### Phase 3 — Jenkins Browser Setup
- Open: `http://<jenkins-ip>:8080`
- Plugins install: Docker Pipeline, Amazon ECR
- Gmail SMTP configure karo (App Password use karo)
- 2 pipelines banao: `cloudpulse-app`, `cloudpulse-infra`
- GitHub webhooks setup karo dono repos pe

### Phase 4 — Infra via Jenkins Pipeline
```
Jenkins → cloudpulse-infra → Build with Parameters → plan  (review karo)
Jenkins → cloudpulse-infra → Build with Parameters → apply → "Yes, Proceed"
# Creates: VPC, EKS cluster, ECR repo (~15 min)
```

### Phase 5 — App First Deploy
```bash
aws eks update-kubeconfig --region ap-south-1 --name cloudpulse-cluster
kubectl apply -k k8s/
kubectl get svc -n cloudpulse   # EXTERNAL-IP = app URL
```

### Phase 6 — Auto Deploy Test
```bash
# app/main.py me version change karo → git push
# Jenkins auto triggers → app update hota hai → email aata hai
```

---

## Two Pipeline Strategy

| Pipeline | Trigger | Stages |
|----------|---------|--------|
| `cloudpulse-app` | Auto on git push | Lint → Docker Build → ECR Push → EKS Deploy |
| `cloudpulse-infra` | Auto triggers plan, manual approval for apply/destroy | Init → Lint → Plan → Approval → Apply/Destroy |

---

## Cost Warning

| Resource | Cost |
|----------|------|
| EC2 t2.micro (Jenkins) | Free tier (750 hrs/month) |
| ECR | Free (500MB) |
| EKS Control Plane | ~$0.10/hr ⚠️ |
| EKS Nodes t3.medium x2 | ~$0.08/hr each ⚠️ |

> **Demo ke baad turant destroy karo!**

---

## Cleanup

```bash
kubectl delete -k k8s/
# Jenkins → cloudpulse-infra → destroy → approve
cd cloudpulse-bootstrap/ && terraform destroy
aws s3 rb s3://cloudpulse-terraform-state --force
```

---

## Prerequisites (Pehle ye install kar)

1. **AWS Account** — Free tier wala chalega
2. **GitHub Account** — 2 repos banane hain
3. **Local machine pe install kar:**
   ```bash
   brew install terraform ansible awscli kubectl
   ```

---

## Step 1: AWS Setup

### 1.1 IAM User bana
- AWS Console → IAM → Users → Create User
- Name: `devops-admin`
- Permissions: `AdministratorAccess` (project ke liye)
- Security Credentials → Create Access Key → CLI use case
- **Access Key ID** aur **Secret Key** save kar

### 1.2 AWS CLI configure kar
```bash
aws configure
# Access Key ID: <paste>
# Secret Access Key: <paste>
# Region: ap-south-1
# Output: json
```

### 1.3 Verify
```bash
aws sts get-caller-identity
```

---

## Step 2: GitHub Repos Create kar

### Repo 1: `cloudpulse-app`
Isme ye folders jayenge:
```
app/
k8s/
jenkins/Jenkinsfile
```

### Repo 2: `cloudpulse-infra`
Isme ye folders jayenge:
```
terraform/
ansible/
jenkins/Jenkinsfile-infra
```

### Push code:
> 💡 **Windows users:** WSL2 terminal mein run karo. Pehle set karo: `export PROJECT_ROOT=~/cloudpulse/simple-app`

```bash
# App repo
mkdir -p /tmp/cloudpulse-app
cp -r $PROJECT_ROOT/app $PROJECT_ROOT/k8s /tmp/cloudpulse-app/
cp $PROJECT_ROOT/jenkins/Jenkinsfile /tmp/cloudpulse-app/Jenkinsfile
cd /tmp/cloudpulse-app
git init && git add . && git commit -m "initial commit"
git remote add origin https://github.com/<username>/cloudpulse-app.git
git push -u origin main

# Infra repo
mkdir -p /tmp/cloudpulse-infra
cp -r $PROJECT_ROOT/terraform $PROJECT_ROOT/ansible /tmp/cloudpulse-infra/
cp $PROJECT_ROOT/jenkins/Jenkinsfile-infra /tmp/cloudpulse-infra/Jenkinsfile
cd /tmp/cloudpulse-infra
git init && git add . && git commit -m "initial commit"
git remote add origin https://github.com/<username>/cloudpulse-infra.git
git push -u origin main
```

---

## Step 3: Infrastructure Deploy (Terraform)

### 3.1 Terraform se infra bana
```bash
cd $PROJECT_ROOT/terraform

terraform init
terraform plan
terraform apply
```

> ⏳ EKS cluster banne me 10-15 min lagta hai. Patient reh.

### 3.2 kubeconfig update kar
```bash
aws eks update-kubeconfig --region ap-south-1 --name cloudpulse-cluster
kubectl get nodes   # nodes dikhne chahiye
```

---

## Step 4: ECR Setup

### 4.1 ECR repo URL note kar
```bash
aws ecr describe-repositories --query 'repositories[0].repositoryUri'
```
Output kuch aisa hoga: `123456789.dkr.ecr.ap-south-1.amazonaws.com/cloudpulse-app`

### 4.2 Jenkinsfile me update kar
`jenkins/Jenkinsfile` me `ECR_REPO` value replace kar actual URL se.

---

## Step 5: Jenkins Server Setup

> ✅ Jenkins EC2 automatically Terraform (cloudpulse-bootstrap) se banta hai — manually launch karne ki zarurat nahi.
> IAM Role (AdministratorAccess) automatically attached hota hai — AWS credentials manually configure karne ki zarurat nahi.

### 5.2 Ansible inventory update kar
```ini
# ansible/inventory.ini
[jenkins]
<JENKINS_PUBLIC_IP> ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/cloudpulse-key.pem
```

### 5.3 Ansible run kar
```bash
cd $PROJECT_ROOT/ansible
ansible-playbook -i inventory.ini setup-jenkins.yml
```

### 5.4 Jenkins access kar
- Browser: `http://<EC2-IP>:8080`
- Initial password:
  ```bash
  ssh -i ~/key.pem ec2-user@<EC2-IP>
  sudo cat /var/lib/jenkins/secrets/initialAdminPassword
  ```
- Install suggested plugins
- Create admin user

---

## Step 6: Jenkins Configuration

### 6.1 Plugins install kar
- Manage Jenkins → Plugins → Available:
  - Docker Pipeline
  - Pipeline: AWS Steps
  - Git

### 6.2 IAM Note
> Jenkins EC2 pe IAM Role (AdministratorAccess) already attached hai — Terraform bootstrap ne kiya. AWS credentials manually add karne ki zarurat **nahi**.

### 6.3 Gmail SMTP setup kar
- Manage Jenkins → System → E-mail Notification
  - SMTP Server: `smtp.gmail.com`
  - Port: 465
  - Use SSL: ✅
  - Username: tera gmail
  - Password: **App Password** (Google Account → Security → App Passwords → Generate)

### 6.4 Pipeline create kar
- New Item → "cloudpulse-app" → Pipeline
- Pipeline → Definition: Pipeline script from SCM
- SCM: Git
- Repo URL: `https://github.com/<username>/cloudpulse-app.git`
- Script Path: `Jenkinsfile`
- Save

---

## Step 7: Kubernetes Namespace bana

```bash
kubectl create namespace cloudpulse
kubectl apply -f k8s/deployment.yaml
```

---

## Step 8: Test the Pipeline

1. App code me koi change kar (e.g., version update in main.py)
2. Git push kar
3. Jenkins me pipeline auto-trigger hogi
4. Build success → email aayegi
5. Check:
   ```bash
   kubectl get pods -n cloudpulse
   kubectl get svc -n cloudpulse   # EXTERNAL-IP se app access kar
   ```

---

## Step 9: Infra Pipeline (Optional)

- Jenkins me second pipeline bana: "cloudpulse-infra"
- Repo: cloudpulse-infra
- Script Path: Jenkinsfile
- Parameters: ACTION (plan/apply/destroy)

---

## Cleanup (Jab kaam ho jaye — IMPORTANT!)

⚠️ **AWS pe paise lagte hain! Kaam hone ke baad destroy kar:**

```bash
# EKS resources delete kar
kubectl delete -f k8s/deployment.yaml

# Terraform se infra destroy kar
cd terraform
terraform destroy

# EC2 instance terminate kar (AWS Console se)
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `terraform init` fails | Check internet connection, run again |
| Jenkins can't reach ECR | EC2 pe IAM role attach kar with ECR permissions |
| kubectl connection refused | `aws eks update-kubeconfig` run kar again |
| Email not working | Gmail App Password use kar, not regular password |
| EKS nodes not ready | Wait 5 min, check Security Group allows all internal traffic |
| Docker permission denied | `sudo usermod -aG docker jenkins && sudo systemctl restart jenkins` |

---

## Cost Estimate (Free Tier)

| Service | Cost |
|---------|------|
| EC2 t2.micro (Jenkins) | FREE (750 hrs/month) |
| ECR | FREE (500 MB storage) |
| EKS Control Plane | $0.10/hour (~$73/month) ⚠️ |
| EKS Nodes (t3.medium x2) | ~$60/month ⚠️ |

> ⚠️ EKS FREE NAHI HAI! Demo ke liye deploy kar, screenshots le, aur **turant destroy kar**.  
> Total cost agar 2-3 hours use kiya: ~$1-2
