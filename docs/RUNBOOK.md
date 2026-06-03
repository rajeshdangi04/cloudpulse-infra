# RUNBOOK — Exact Commands to Run Everything

Ye tera actual execution guide hai. Ek ek step copy-paste kar aur run kar.

---

## Phase 0: Local Machine Setup (Windows)

```bash
# Install required tools:
# Terraform: https://developer.hashicorp.com/terraform/downloads → Windows AMD64
# AWS CLI:   https://aws.amazon.com/cli/ → Windows MSI
# kubectl:   https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
# Git:       https://git-scm.com/download/win

# Verify (PowerShell / Windows Terminal)
terraform --version
aws --version
kubectl version --client
git --version
```

> 💡 **Ansible locally install karne ki zarurat nahi** — Ansible server AWS pe automatically banta hai (Terraform se)

---

## Phase 1: AWS Setup

### 1.1 IAM User
- AWS Console → IAM → Users → Create User → `devops-admin`
- Permissions: `AdministratorAccess`
- Security Credentials → Create Access Key → CLI → Save keys

### 1.2 AWS CLI Configure
```bash
aws configure
# AWS Access Key ID: <paste>
# AWS Secret Access Key: <paste>
# Default region: ap-south-1
# Default output: json

# Verify
aws sts get-caller-identity
```

### 1.3 S3 Bucket for Terraform State
```bash
aws s3 mb s3://cloudpulse-terraform-state --region ap-south-1

# Verify
aws s3 ls | grep cloudpulse
```

### 1.4 EC2 Key Pair
- AWS Console → EC2 → Key Pairs → Create Key Pair
- Name: `cloudpulse-key`
- Type: RSA, Format: `.pem`
- Download aur save karo: `~/cloudpulse-key.pem`

```bash
chmod 400 ~/cloudpulse-key.pem
```

---

## Phase 2: GitHub Repos Create Karo (3 Repos)

GitHub pe **3 repos** banao:
- `cloudpulse-bootstrap` (public)
- `cloudpulse-app` (public)
- `cloudpulse-infra` (public)

```bash
# Repo 1: cloudpulse-bootstrap
cd cloudpulse-bootstrap/
git init
git add .
git commit -m "initial: bootstrap infra for jenkins + ansible servers"
git remote add origin https://github.com/<username>/cloudpulse-bootstrap.git
git push -u origin main

# Repo 2: cloudpulse-app
cd cloudpulse-app/
git init
git add .
git commit -m "initial: flask app + k8s manifests + jenkinsfile"
git remote add origin https://github.com/<username>/cloudpulse-app.git
git push -u origin main

# Repo 3: cloudpulse-infra
cd cloudpulse-infra/
git init
git add .
git commit -m "initial: terraform modules + ansible roles + infra pipeline"
git remote add origin https://github.com/<username>/cloudpulse-infra.git
git push -u origin main
```

---

## Phase 3: Bootstrap — Jenkins + Ansible EC2 Banao

```bash
cd cloudpulse-bootstrap/

# terraform.tfvars banao
cp terraform.tfvars.example terraform.tfvars
# Sirf key_name fill karo — VPC khud banta hai automatically
# nano terraform.tfvars   (key_name = "cloudpulse-key" set karo)

terraform init
terraform plan
terraform apply
```

> ✅ **Kya banta hai:**
> - `cloudpulse-bootstrap-vpc` — Bootstrap VPC (10.10.0.0/16) — Main infra se bilkul alag
> - `cloudpulse-jenkins-server` — Jenkins EC2, **IAM Role attached** (AdministratorAccess — Terraform + ECR + EKS sab access)
> - `cloudpulse-ansible-server` — Ansible EC2, Ansible pre-installed via user_data
>
> Output mein **dono IPs** aayenge:
> ```
> jenkins_public_ip = "13.235.xx.xx"
> ansible_public_ip = "13.235.yy.yy"
> ```

---

## Phase 4: Ansible Server pe Playbooks Copy Karo

```bash
# Step 1: Ansible server pe infra repo clone karo
ssh -i ~/cloudpulse-key.pem ec2-user@<ANSIBLE_PUBLIC_IP>

# Ansible server ke andar:
cd /home/ec2-user/cloudpulse
git clone https://github.com/<YOUR_GITHUB_USERNAME>/cloudpulse-infra.git infra
cd infra

# SSH key Ansible server pe copy karo (local machine se):
# (exit ansible server first, run this on local)
exit
scp -i ~/cloudpulse-key.pem ~/cloudpulse-key.pem ec2-user@<ANSIBLE_PUBLIC_IP>:~/.ssh/cloudpulse-key.pem
ssh -i ~/cloudpulse-key.pem ec2-user@<ANSIBLE_PUBLIC_IP> "chmod 400 ~/.ssh/cloudpulse-key.pem"
```

## Phase 5: Ansible — Jenkins Configure Karo

```bash
# Ansible server pe SSH karo
ssh -i ~/cloudpulse-key.pem ec2-user@<ANSIBLE_PUBLIC_IP>

# inventory.ini me Jenkins IP update karo
cd /home/ec2-user/cloudpulse/infra/ansible
sed -i 's/<JENKINS_EC2_IP>/<JENKINS_PUBLIC_IP>/' inventory.ini

# Ya manually edit karo:
# nano inventory.ini  → <JENKINS_EC2_IP> ko Jenkins IP se replace karo

# Wait 2-3 min for Jenkins EC2 to fully boot, phir:
ansible jenkins -i inventory.ini -m ping    # pehle connection test

ansible-playbook -i inventory.ini setup-jenkins.yml
```

---

## Phase 6: Jenkins Configure Karo (Browser)

### 5.1 Initial Setup
```
http://<JENKINS_PUBLIC_IP>:8080
```

```bash
# Initial admin password:
ssh -i ~/cloudpulse-key.pem ec2-user@<JENKINS_PUBLIC_IP>
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

- Paste password → Install suggested plugins → Create admin user

### 5.2 Plugins Install
Manage Jenkins → Plugins → Available Plugins — install karo:
- `Docker Pipeline`
- `Amazon ECR`
- `Pipeline: AWS Steps`

### 5.3 Gmail SMTP Configure
Manage Jenkins → System → E-mail Notification:
```
SMTP Server:  smtp.gmail.com
Port:         465
Use SSL:      ✅
Username:     umeshdangi@gmail.com
Password:     <Gmail App Password>
```

> Gmail App Password banane ke liye: Google Account → Security → 2-Step Verification ON karo → App Passwords → Generate

### 5.4 App Pipeline Banao
- New Item → `cloudpulse-app` → Pipeline → OK
- Build Triggers → ✅ `GitHub hook trigger for GITScm polling`
- Pipeline → SCM: Git
- Repository URL: `https://github.com/<username>/cloudpulse-app.git`
- Script Path: `Jenkinsfile`
- Save

### 5.5 Infra Pipeline Banao
- New Item → `cloudpulse-infra` → Pipeline → OK
- Build Triggers → ✅ `GitHub hook trigger for GITScm polling`
- Pipeline → SCM: Git
- Repository URL: `https://github.com/<username>/cloudpulse-infra.git`
- Script Path: `jenkins/Jenkinsfile`
- Save

---

## Phase 6: GitHub Webhooks Setup

### App Repo Webhook
- `cloudpulse-app` → Settings → Webhooks → Add webhook
- Payload URL: `http://<JENKINS_IP>:8080/github-webhook/`
- Content type: `application/json`
- Events: Just the push event → Add webhook

### Infra Repo Webhook
- Same steps for `cloudpulse-infra` repo

---

## Phase 7: Infra Deploy — VPC + EKS + ECR

```
Jenkins → cloudpulse-infra → Build with Parameters
→ ACTION: plan → Build
```

Plan output review karo. Sab theek lage toh:

```
Jenkins → cloudpulse-infra → Build with Parameters
→ ACTION: apply → Build → "Yes, Proceed" click karo
```

> ⏳ EKS banne me 10-15 min lagta hai. Wait karo.

```bash
# Jab pipeline complete ho:
aws eks update-kubeconfig --region ap-south-1 --name cloudpulse-cluster

# Verify nodes ready hain:
kubectl get nodes
```

---

## Phase 8: Jenkinsfile me ECR URL Update Karo

```bash
# ECR URL nikalo:
aws ecr describe-repositories --query 'repositories[0].repositoryUri' --output text
# Output: 123456789012.dkr.ecr.ap-south-1.amazonaws.com/cloudpulse-app
```

- `jenkins/Jenkinsfile` me `ECR_REPO` value update karo actual URL se
- Git push karo

---

## Phase 9: App Deploy — First Time

```bash
# Namespace banao
kubectl create namespace cloudpulse

# K8s manifests apply karo
kubectl apply -k k8s/

# Pods check karo
kubectl get pods -n cloudpulse

# Service/URL check karo (EXTERNAL-IP milne me 2-3 min lagta hai)
kubectl get svc -n cloudpulse
```

App: `http://<EXTERNAL-IP>` → `Hello from CloudPulse! Version 1.0`

---

## Phase 10: Test Auto-Deploy

```bash
# main.py me version change karo
# Line: return f"Hello from CloudPulse! Version 2.0"

git add .
git commit -m "update: version 2.0"
git push
```

Jenkins pe jaao — pipeline automatically trigger hogi. Build complete hone ke baad browser refresh karo → `Version 2.0` dikhega + email aayegi. ✅

---

## Cleanup — Sab Delete Karo (IMPORTANT!)

```bash
# Step 1: K8s resources delete karo
kubectl delete -k k8s/

# Step 2: EKS + VPC + ECR destroy karo
# Jenkins → cloudpulse-infra → Build with Parameters → destroy → "Yes, Proceed"

# Step 3: Bootstrap EC2 + VPC destroy karo
cd cloudpulse-bootstrap/
terraform destroy

# Step 4: S3 bucket delete karo
aws s3 rm s3://cloudpulse-terraform-state --recursive
aws s3 rb s3://cloudpulse-terraform-state
```

> ⚠️ **EKS ~$0.10/hr charge karta hai.** 3 ghante me ~$1. Demo ke baad turant destroy karo!

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `terraform init` fails | `aws sts get-caller-identity` check karo — credentials sahi hain? |
| Ansible ping fails | EC2 boot hone do (2 min wait), security group me port 22 open hai? |
| Jenkins can't push to ECR | Jenkins EC2 IAM Role check karo — `AdministratorAccess` attached hai? Bootstrap terraform se automatically attach hota hai |
| `kubectl` connection refused | `aws eks update-kubeconfig` dobara run karo |
| Email nahi aa raha | Gmail App Password use karo, regular password nahi |
| EKS nodes NotReady | 5 min wait karo, `kubectl describe node` se reason dekho |
| Docker permission denied | `sudo usermod -aG docker jenkins && sudo systemctl restart jenkins` |
| Pipeline nahi trigger ho rahi | GitHub webhook pe green tick hai? Jenkins URL publicly accessible hai? |
