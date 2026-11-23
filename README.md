# AWS EKS CI/CD Pipeline (`eks-cicd-demo`)

End-to-end CI/CD pipeline and containerized Node.js application deployed to **Amazon EKS** using **GitHub Actions**, **Docker**, **Trivy**, and **Amazon ECR** (with infrastructure provisioned via Terraform / AWS Console).

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
│   ├── deployment.yaml     # Kubernetes Deployment manifest
│   └── service.yaml        # Kubernetes Service manifest (LoadBalancer)
└── README.md
```

---

## Pipeline Overview

On pushes to `main` (or manual workflow dispatch), `.github/workflows/ci-cd.yml` runs:

1. **Checkout & AWS Auth:** Checks out the repository and authenticates to AWS using GitHub Secrets.
2. **ECR Login:** Logs into Amazon ECR.
3. **Build & Test:** Builds the Docker image from `./app/Dockerfile` (running unit tests inside the build) and tags it with `${{ github.sha }}` and `latest`.
4. **Security Scan:** Scans the built image with **Trivy** (`CRITICAL` severity gate).
5. **Push to ECR:** Pushes the tagged image to Amazon ECR.
6. **Deploy to EKS:** Updates `kubeconfig` for the target EKS cluster, updates the deployment image to the commit SHA tag, and waits for `kubectl rollout status`.

---

## Required GitHub Actions Secrets

Configure these under **GitHub Repository → Settings → Secrets and variables → Actions**:

| Secret Name | Description | Example |
| :--- | :--- | :--- |
| `AWS_ACCESS_KEY_ID` | IAM access key ID with ECR & EKS permissions | `AKIA...` |
| `AWS_SECRET_ACCESS_KEY` | IAM secret access key | `wJalr...` |
| `AWS_REGION` | AWS region where ECR and EKS reside | `eu-central-1` |
| `ECR_REPOSITORY` | ECR repository name | `devops-demo-app` |
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
kubectl get pods
kubectl get svc
```

Once the `LoadBalancer` service has an `EXTERNAL-IP` (`*.elb.amazonaws.com`), open `http://<EXTERNAL-IP>` in your browser to verify the live deployment.

---

## Cleanup (Avoid Idle AWS Charges)

When finished testing or presenting, remove billable AWS resources in reverse order:

1. Delete Kubernetes resources (`kubectl delete -f k8s/`) and verify no leftover Load Balancers remain in **EC2 → Load Balancers**.
2. Delete the EKS **Node group**, then delete the **EKS cluster**.
3. Delete test images/repositories in **ECR** and rotate/remove temporary IAM access keys if no longer needed.