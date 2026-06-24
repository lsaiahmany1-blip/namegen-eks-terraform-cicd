# NameGen on AWS EKS Auto Mode

## 1. Project Overview

This repository contains Project #3: a fully automated deployment of the Red Hat NameGen application to AWS EKS Auto Mode.

The source application is copied into the repository root from:

```text
https://github.com/redhat-developer-demos/namegen
```

The project uses Terraform for AWS infrastructure, GitHub Actions as the primary orchestrator, Amazon ECR for the Docker image, and Kubernetes manifests for application deployment.

## 2. Architecture

```text
GitHub Actions
  -> Terraform provisions AWS infrastructure
  -> EKS Auto Mode runs Kubernetes workloads
  -> ECR stores the NameGen Docker image
  -> kubectl applies Kubernetes manifests
  -> AWS Network Load Balancer exposes the application
```

Main components:

- AWS VPC with public and private subnets
- Internet Gateway and NAT Gateway
- EKS Auto Mode cluster
- ECR repository
- GitHub Actions OIDC role
- Kubernetes namespace, deployments, services, StatefulSet, and PVC
- AWS Network Load Balancer for external access

Architecture diagram:

```text
diagrams/architecture.drawio
```

## 3. Repository Structure

```text
.
|-- .github/
|   `-- workflows/
|       `-- deploy.yml
|-- terraform/
|   |-- versions.tf
|   |-- providers.tf
|   |-- variables.tf
|   |-- outputs.tf
|   `-- main.tf
|-- kubernetes/
|   |-- namespace.yaml
|   |-- mongodb-secret.yaml
|   |-- mongodb-service.yaml
|   |-- mongodb-statefulset.yaml
|   |-- namegen-deployment.yaml
|   |-- namegen-service.yaml
|   `-- kustomization.yaml
|-- diagrams/
|   `-- architecture.drawio
|-- screenshots/
|   `-- README.md
|-- Dockerfile
|-- README.md
`-- application source code files
```

## 4. Infrastructure Provisioning with Terraform

Terraform provisions the AWS infrastructure required by the project:

- VPC
- Public subnets
- Private subnets
- Internet Gateway
- NAT Gateway
- Route tables and subnet associations
- EKS Auto Mode cluster
- ECR repository
- IAM roles and policies
- GitHub Actions OIDC integration

The EKS cluster uses private subnets. Public subnets are tagged for internet-facing Kubernetes load balancers, and private subnets are tagged for internal Kubernetes load balancers.

Terraform files are located in:

```text
terraform/
```

## 5. CI/CD Pipeline with GitHub Actions

GitHub Actions is the primary orchestrator. The workflow is located at:

```text
.github/workflows/deploy.yml
```

The pipeline performs these steps:

1. Authenticate to AWS using GitHub Actions OIDC.
2. Run Terraform init, validate, plan, and apply.
3. Read Terraform outputs for the EKS cluster and ECR repository.
4. Build the NameGen Docker image.
5. Push the image to Amazon ECR.
6. Configure kubectl for the EKS cluster.
7. Apply Kubernetes manifests.
8. Update the NameGen deployment image.
9. Validate rollout, pods, services, PVCs, events, and LoadBalancer address.

### One-Time Setup

Before the first workflow run, create the mandatory GitHub Actions OIDC bootstrap role in AWS. This is required because GitHub Actions must assume an AWS role before Terraform can run.

Create this GitHub repository secret:

```text
AWS_GITHUB_ACTIONS_ROLE_ARN
```

The value is the ARN of the AWS IAM role trusted by GitHub Actions OIDC, for example:

```text
arn:aws:iam::<AWS_ACCOUNT_ID>:role/<ROLE_NAME>
```

Minimum manual setup:

1. Create or confirm the AWS IAM OIDC provider for GitHub Actions:

   ```text
   https://token.actions.githubusercontent.com
   ```

2. Create one IAM role that trusts this repository and branch:

   ```text
   repo:lsaiahmany1-blip/namegen-eks-terraform-cicd:ref:refs/heads/main
   ```

3. Copy the role ARN.
4. Add the ARN to GitHub as the secret `AWS_GITHUB_ACTIONS_ROLE_ARN`.
5. Create or confirm the GitHub Actions variable:

   ```text
   AWS_REGION=us-east-1
   ```

After this one-time setup, the deployment flow is automated through GitHub Actions.

## 6. Kubernetes Workloads

Kubernetes manifests are stored in:

```text
kubernetes/
```

The manifests deploy:

- Namespace: `namegen`
- MongoDB Secret
- MongoDB headless Service
- MongoDB StatefulSet
- NameGen Deployment
- NameGen LoadBalancer Service
- Kustomize configuration

The NameGen deployment uses this required environment variable:

```text
MONGODB_URL=mongodb://genuser:password@mongodb/namegen
```

## 7. MongoDB Persistence

MongoDB is deployed as a Kubernetes StatefulSet using the required image:

```text
mongodb:3.6
```

Persistent storage is configured with a `volumeClaimTemplates` section in:

```text
kubernetes/mongodb-statefulset.yaml
```

The PVC requests persistent storage for MongoDB data at:

```text
/data/db
```

## 8. Application Access through NLB

The NameGen application is exposed with a Kubernetes `LoadBalancer` Service:

```text
kubernetes/namegen-service.yaml
```

The service includes AWS annotations for Network Load Balancer support:

```yaml
service.beta.kubernetes.io/aws-load-balancer-type: external
service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
```

After deployment, the application is available through the LoadBalancer hostname or address shown by Kubernetes.

## 9. Validation Commands

The GitHub Actions workflow runs validation commands automatically after deployment.

Useful commands for checking the deployment:

```bash
kubectl -n namegen rollout status deployment/namegen
kubectl -n namegen get pods -o wide
kubectl -n namegen get services -o wide
kubectl -n namegen get pvc
kubectl -n namegen get events --sort-by=.lastTimestamp
kubectl -n namegen get service namegen
```

To print only the LoadBalancer hostname or IP:

```bash
kubectl -n namegen get service namegen -o jsonpath='{.status.loadBalancer.ingress[0].hostname}{"\n"}{.status.loadBalancer.ingress[0].ip}{"\n"}'
```

## 10. Screenshots

Submission screenshots should be placed in:

```text
screenshots/
```

Suggested screenshots:

- Successful GitHub Actions workflow run
- Terraform-created EKS cluster
- ECR repository with the pushed NameGen image
- Kubernetes pods, services, and PVC
- Browser showing the NameGen application through the AWS NLB

## 11. Cleanup

Infrastructure should be removed with Terraform when the project is complete:

```bash
cd terraform
terraform destroy
```

Kubernetes resources are managed by the workflow and the EKS cluster. Destroying the Terraform-managed infrastructure removes the cluster, networking resources, and ECR repository.

## 12. Troubleshooting

Common checks:

- If AWS authentication fails, verify `AWS_GITHUB_ACTIONS_ROLE_ARN` exists in GitHub repository secrets.
- If OIDC authentication fails, verify the IAM role trust policy allows the repository and `main` branch.
- If Terraform cannot create resources, verify the bootstrap role has the required AWS permissions.
- If the image cannot be pulled, verify the image was pushed to ECR and the EKS nodes can read from ECR.
- If MongoDB does not start, check the StatefulSet, PVC, and events in the `namegen` namespace.
- If the application cannot connect to MongoDB, verify:

  ```text
  MONGODB_URL=mongodb://genuser:password@mongodb/namegen
  ```

- If the LoadBalancer address is empty, wait a few minutes and check:

  ```bash
  kubectl -n namegen get service namegen
  kubectl -n namegen get events --sort-by=.lastTimestamp
  ```
