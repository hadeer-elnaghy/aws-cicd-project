# AWS EKS CI/CD Pipeline (`aws-cicd-project`)

End-to-end CI/CD pipeline and containerized Node.js application deployed to **Amazon EKS** using **GitHub Actions**, **Docker**, **Trivy**, and **Amazon ECR**, with private subnet isolation for compute and stateful/database workloads.

---

## Repository Structure

```text
.
├── .github/
│   └── workflows/
│       └── ci-cd.yml       # Build, test, Trivy scan, ECR push, and EKS rollout
├── app/
│   ├── public/
│   │   └── index.html
│   ├── src/
│   │   └── server.js
│   ├── tests/
│   │   └── app.test.js
│   ├── Dockerfile          # Multi-stage build running tests and packaging app
│   ├── .dockerignore       # Excludes node_modules, .env, .git, etc. (keeps Dockerfile)
│   ├── package.json
│   └── package-lock.json
├── k8s/
│   ├── configmap.yaml      # Non-sensitive DB/app config (DB_HOST, DB_PORT, DB_NAME)
│   ├── deployment.yaml     # Kubernetes Deployment mounting ConfigMap & Secret via envFrom
│   └── service.yaml        # Kubernetes Service manifest (LoadBalancer)
└── README.md
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

## What to Get From AWS

Before running the pipeline or configuring cluster secrets, obtain these details from your AWS / Terraform setup:

* **AWS Region (`AWS_REGION`):** The region where ECR, EKS, VPC subnets, and RDS live.
* **Private ECR Repository (`ECR_REPOSITORY`):** Exact repository name (e.g., `devops-demo-app`).
* **EKS Cluster Name (`EKS_CLUSTER_NAME`):** Exact cluster name with worker nodes in private subnets and proper node IAM policies.
* **IAM & Cluster Access:** Credentials (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`) with ECR push and EKS access permissions, plus cluster access mapping for `kubectl`.
* **Private Database (RDS) Details:** Endpoint (`DB_HOST`), port (`DB_PORT`, typically `3306`), database name (`DB_NAME`), username (`DB_USER`), and password (`DB_PASSWORD`), with RDS in private subnets and port `5432` allowed only from the EKS security group.

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

## Kubernetes Secret (`app-db-secret`)

Point `kubectl` to your EKS cluster and create the secret directly on the cluster (outside Git) so database credentials are injected into your pods without being committed to the repository:

```bash
aws eks update-kubeconfig --name <EKS_CLUSTER_NAME> --region <AWS_REGION>

kubectl create secret generic app-db-secret \
  --from-literal=DB_USER="<DB_USERNAME>" \
  --from-literal=DB_PASSWORD="<DB_PASSWORD>"
```

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

## Cleanup (Avoid Idle AWS Charges)

When finished testing or presenting, remove billable AWS resources in reverse order:

1. Delete Kubernetes resources (`kubectl delete -f k8s/`) and verify no leftover Load Balancers remain in **EC2 → Load Balancers**.
2. Delete the **RDS database instance** (if created) before deleting VPC/subnets.
3. Delete the EKS **Node group**, then delete the **EKS cluster**.
4. Delete NAT Gateways / unused VPC resources if provisioned for testing.
5. Delete test images/repositories in **ECR** and rotate/remove temporary IAM access keys if no longer needed.