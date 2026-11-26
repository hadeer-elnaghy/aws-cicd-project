# AWS EKS CI/CD Pipeline (`aws-cicd-project`)

End-to-end Infrastructure as Code (IaC) and CI/CD pipeline for a containerized Node.js application deployed to **Amazon EKS**. The infrastructure is provisioned and managed using **Terraform**, automated delivery is driven by **GitHub Actions**, **Docker**, **Trivy**, and **Amazon ECR**, with compute and stateful database workloads isolated in private VPC subnets. Monitoring, log aggregation, and real-time alert notifications are powered by **Amazon CloudWatch** and **Amazon SNS**.

---

## Repository Structure

```text
.
├── .github/
│   └── workflows/
│       └── ci-cd.yml           # GitHub Actions CI/CD (test, Trivy scan, ECR push, EKS rollout)
├── app/
│   ├── public/
│   │   └── index.html          # Frontend dashboard UI
│   ├── src/
│   │   ├── db.js               # PostgreSQL connection pool & query handler
│   │   └── server.js           # Express API server (/health, /api/releases, static frontend)
│   ├── tests/
│   │   └── app.test.js         # Automated tests for application endpoints
│   ├── .dockerignore           # Excludes node_modules, .env, and local artifacts from build
│   ├── Dockerfile              # Multi-stage Docker build running tests & packaging app
│   ├── package.json            # Node.js project manifest and scripts
│   └── package-lock.json       # Exact dependency tree lockfile
├── db/
│   └── init.sql                # PostgreSQL schema and initial seed data for releases
├── k8s/
│   ├── configmap.yaml          # Non-sensitive DB/app config (DB_HOST, DB_PORT, DB_NAME)
│   ├── db-init-job.yaml        # Kubernetes Job initializing the RDS PostgreSQL schema
│   ├── deployment.yaml         # Kubernetes Deployment mounting ConfigMap & Secret via envFrom
│   └── service.yaml            # Kubernetes Service manifest (LoadBalancer)
├── terraform/
│   ├── bootstrap/              # S3 bucket & DynamoDB lock table for remote state
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── providers.tf
│   │   └── versions.tf
│   ├── dev/                    # Environment infrastructure orchestration
│   │   ├── backend.tf          # Remote S3 backend & DynamoDB state locking
│   │   ├── main.tf             # Module composition (VPC, IAM, ECR, EKS, RDS)
│   │   ├── outputs.tf          # Infrastructure outputs (ECR URL, EKS cluster, RDS endpoint)
│   │   ├── providers.tf        # AWS provider setup
│   │   ├── variables.tf        # Input variable definitions
│   │   └── versions.tf         # Terraform and AWS provider version constraints
│   └── modules/                # Reusable Infrastructure-as-Code modules
│       ├── ecr/                # Amazon ECR container repository
│       ├── eks/                # Amazon EKS cluster and managed node groups
│       ├── iam/                # IAM roles and policies for EKS & CI/CD deployment
│       ├── rds/                # Amazon RDS PostgreSQL instance and subnet groups
│       └── vpc/                # VPC, public/private subnets, NAT Gateway, and route tables
├── .gitignore                  # Git ignore rules for build artifacts, state files, and secrets
└── README.md                   # Project documentation
```

---

## Pipeline Overview

On pushes to `main` (or manual workflow dispatch), `.github/workflows/ci-cd.yml` runs:

1. **Checkout & AWS Auth:** Checks out the repository and authenticates to AWS using GitHub Secrets.
2. **ECR Login:** Authenticates Docker with Amazon ECR.
3. **Build & Test:** Builds the Docker image from `./app/Dockerfile` (running unit tests inside the build) and tags it with `${{ github.sha }}` and `latest`.
4. **Security Scan:** Scans the built image with **Trivy** (`CRITICAL` severity gate).
5. **Push to ECR:** Pushes the tagged image to Amazon ECR.
6. **Deploy to EKS:** Updates `kubeconfig` for the target EKS cluster, applies Kubernetes manifests (`k8s/configmap.yaml`, `k8s/deployment.yaml`, `k8s/service.yaml`), updates the deployment image to the commit SHA tag, and waits for `kubectl rollout status`.

---

## Infrastructure Provisioning (Terraform)

All core AWS infrastructure is declared as code under the `terraform/` directory:

* **Remote State Bootstrap (`terraform/bootstrap`):** Provisions an S3 bucket (with AES-256 encryption and versioning enabled) and a DynamoDB table for distributed state locking.
* **Environment Provisioning (`terraform/dev`):** Assembles the environment using reusable modules:
  * **VPC Module (`modules/vpc`):** Multi-AZ VPC with public subnets (Internet Gateway) and private subnets (NAT Gateway) tagged for Kubernetes integration.
  * **IAM Module (`modules/iam`):** IAM roles and policies for EKS cluster control plane, worker node groups, and CI/CD deployer access.
  * **ECR Module (`modules/ecr`):** Private Docker container repository with scan-on-push image vulnerability scanning.
  * **EKS Module (`modules/eks`):** Managed Kubernetes control plane and node groups running securely in private subnets.
  * **RDS Module (`modules/rds`):** Private PostgreSQL database instance with a dedicated subnet group, accessible exclusively from the EKS security group on port `5432`.

### Deploying Infrastructure

```bash
# 1. Bootstrap remote state storage (S3 + DynamoDB)
cd terraform/bootstrap
terraform init
terraform apply -auto-approve

# 2. Deploy core cloud resources
cd ../dev
terraform init
terraform apply -auto-approve
```

---

## What to Get From AWS / Terraform

Before running the pipeline or configuring cluster secrets, obtain these details directly from `terraform output` (or the AWS console):

* **AWS Region (`AWS_REGION`):** Target AWS region (e.g., `eu-north-1` or `eu-central-1`).
* **Private ECR Repository (`ECR_REPOSITORY`):** Repository name obtained from `terraform output ecr_repository_url`.
* **EKS Cluster Name (`EKS_CLUSTER_NAME`):** Cluster name obtained from `terraform output eks_cluster_name`.
* **IAM & Cluster Access:** Credentials (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) with ECR push and EKS access permissions, mapped into EKS access entries.
* **Private Database (RDS) Details:** Endpoint (`DB_HOST` from `terraform output rds_endpoint` / `rds_address`), port (`DB_PORT`, default `5432` for PostgreSQL), database name (`DB_NAME`), username (`DB_USER`), and password (`DB_PASSWORD`), with RDS in private subnets and port `5432` allowed only from the EKS security group.

---

## Required GitHub Actions Secrets

Configure these under **GitHub Repository → Settings → Secrets and variables → Actions**:

| Secret Name | Description | Example |
| :--- | :--- | :--- |
| `AWS_ACCESS_KEY_ID` | IAM access key ID with ECR & EKS permissions | `AKIA...` |
| `AWS_SECRET_ACCESS_KEY` | IAM secret access key | `wJalr...` |
| `AWS_REGION` | AWS region where ECR, EKS, and RDS reside | `eu-central-1` |
| `ECR_REPOSITORY` | Private ECR repository name | `devops-demo-app` |
| `EKS_CLUSTER_NAME` | Target Amazon EKS cluster name | `devops-demo-cluster` |

---

## Local Development & Verification

### Run Tests & Start App Locally
```bash
cd app
npm install
npm test
npm start
```

### Build & Run Docker Container Locally
```bash
cd app
docker build -t devops-demo-app:local .
docker run --rm -p 3000:3000 devops-demo-app:local
```

---

## Kubernetes & Live Endpoint Check

After a successful GitHub Actions deployment, configure `kubectl` for your cluster and inspect the rollout:

```bash
aws eks update-kubeconfig --name <EKS_CLUSTER_NAME> --region <AWS_REGION>
kubectl get configmap app-db-config
kubectl get secret app-db-secret
kubectl get pods -o wide
kubectl get svc
```

Once the `LoadBalancer` service has an `EXTERNAL-IP` (`*.elb.amazonaws.com`), open `http://<EXTERNAL-IP>` in your browser to verify the live deployment.

---

## Observability & Alerting (Amazon CloudWatch & SNS)

To ensure high availability, proactive failure detection, and fast incident response, the platform integrates **Amazon CloudWatch** and **Amazon SNS**:

* **CloudWatch Container Insights:** Collects compute performance metrics (including CPU and memory utilization, disk usage, pod restart counts) across the EKS cluster, worker nodes, and individual application pods.
* **CloudWatch Logs:** Centralized log streaming for application containers, pod stdout/stderr, and Kubernetes control plane audit events.
* **CloudWatch Metric Alarms:** Automated alarms track key health thresholds:
  * **Container CPU (`container_cpu_request`):** Monitors container CPU demand against requested CPU allocations (`100m`) in Container Insights, triggering an alarm before pods face CPU throttling, starvation, or degradation.
  * **Workload Health:** Detects abnormal pod restart spikes (`CrashLoopBackOff`) or failed container `/health` probes.
  * **Application Response:** Monitors elevated HTTP `5xx` error responses from the application.
* **Amazon SNS (Simple Notification Service):** CloudWatch alarms automatically publish events to an SNS notification topic (`eks-cloudwatch-alerts`), dispatching immediate alerts to team communication channels (Email, Slack webhooks, or SMS).

---

## Cleanup (Avoid Idle AWS Charges)

When finished testing or presenting, tear down billable AWS resources in reverse order to avoid lingering charges:

1. Delete Kubernetes workloads to automatically deprovision ELB load balancers:
   ```bash
   kubectl delete -f k8s/
   ```
2. Verify in **EC2 → Load Balancers** that no orphan load balancers remain.
3. Destroy core infrastructure via Terraform:
   ```bash
   cd terraform/dev
   terraform destroy -auto-approve
   ```
4. (Optional) Destroy remote state backend if no longer needed:
   ```bash
   cd ../bootstrap
   terraform destroy -auto-approve
   ```
5. Rotate or remove temporary IAM access keys used for GitHub Actions.