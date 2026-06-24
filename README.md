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
|   |-- backend.tf
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
- EKS Auto Mode block storage
- ECR repository
- IAM roles and policies
- GitHub Actions OIDC integration

The EKS cluster uses private subnets. Public subnets are tagged for internet-facing Kubernetes load balancers, and private subnets are tagged for internal Kubernetes load balancers.

Terraform files are located in:

```text
terraform/
```

Terraform state is stored remotely in S3 so GitHub Actions can keep track of infrastructure between workflow runs. DynamoDB is used for state locking to prevent concurrent Terraform runs from modifying the same state at the same time.

## 5. CI/CD Pipeline with GitHub Actions

GitHub Actions is the primary orchestrator. The workflow is located at:

```text
.github/workflows/deploy.yml
```

The pipeline performs these steps:

1. Authenticate to AWS using GitHub Actions OIDC.
2. Bootstrap the Terraform remote state backend in S3 and DynamoDB.
3. Run Terraform init, validate, plan, and apply.
4. Read Terraform outputs for the EKS cluster and ECR repository.
5. Build the NameGen Docker image.
6. Push the image to Amazon ECR.
7. Configure kubectl for the EKS cluster.
8. Apply Kubernetes manifests.
9. Update the NameGen deployment image.
10. Validate rollout, pods, services, PVCs, events, and LoadBalancer address.

### One-Time Setup

Before the first workflow run, complete the mandatory OIDC setup below. The Terraform remote state S3 bucket and DynamoDB lock table are created automatically by the workflow.

#### AWS OIDC Bootstrap

Create the mandatory GitHub Actions OIDC bootstrap role in AWS. This is required because GitHub Actions must assume an AWS role before Terraform can run.

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

#### Terraform Remote State Bootstrap

The workflow automatically creates the Terraform remote state backend before running `terraform init`.

Default values:

```text
TF_STATE_BUCKET=namegen-terraform-state-452670588645
TF_STATE_KEY=namegen/dev/terraform.tfstate
TF_LOCK_TABLE=terraform-locks
```

The workflow:

- Creates the S3 state bucket if it does not already exist
- Enables S3 bucket versioning
- Enables S3 bucket encryption
- Blocks public access on the S3 bucket
- Creates the DynamoDB lock table if it does not already exist
- Waits until the DynamoDB table exists before running `terraform init`

Optional GitHub Actions repository variables can override the defaults:

```text
TF_STATE_BUCKET=<custom-s3-state-bucket-name>
TF_STATE_KEY=<custom-state-key>
TF_LOCK_TABLE=<custom-dynamodb-lock-table>
```

The workflow passes these values to `terraform init`, so Terraform state persists between GitHub Actions runs. This prevents Terraform from losing track of infrastructure that was created during earlier runs.

After this one-time setup, the deployment flow is automated through GitHub Actions.

### Existing Resource Recovery

If AWS resources were created before the S3 backend was enabled, Terraform may fail because the new remote state does not know about those resources yet.

Typical errors:

```text
RepositoryAlreadyExistsException: The repository with name 'namegen' already exists
EntityAlreadyExists: Role with name namegen-dev-eks-cluster-role already exists
EntityAlreadyExists: Role with name namegen-dev-eks-node-role already exists
EntityAlreadyExists: Role with name namegen-dev-github-actions-role already exists
```

These conflicts come from Terraform resources with fixed names:

```text
aws_ecr_repository.namegen
aws_iam_role.eks_cluster
aws_iam_role.eks_node
aws_iam_role.github_actions
aws_iam_role_policy_attachment.*
```

Safest approach:

- Import existing project resources into the S3-backed Terraform state when they are valid resources that should remain part of this project.
- Do not manually recreate resources that already exist.
- Do not delete shared or valid project resources just to make Terraform apply pass.
- If an EKS cluster from a failed run is already being deleted, wait until AWS finishes deleting it before running the workflow again. Do not import a cluster that is in `DELETING` state.

Example recovery flow after the backend bucket and lock table exist:

```bash
cd terraform

terraform init \
  -backend-config="bucket=namegen-terraform-state-452670588645" \
  -backend-config="key=namegen/dev/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="dynamodb_table=terraform-locks" \
  -backend-config="encrypt=true"

terraform import aws_ecr_repository.namegen namegen
terraform import aws_iam_role.eks_cluster namegen-dev-eks-cluster-role
terraform import aws_iam_role.eks_node namegen-dev-eks-node-role
terraform import aws_iam_role.github_actions namegen-dev-github-actions-role
```

If policy attachments already exist, import them using the Terraform resource address and the AWS import ID format `role-name/policy-arn`. Examples:

```bash
terraform import aws_iam_role_policy_attachment.eks_cluster_policy \
  namegen-dev-eks-cluster-role/arn:aws:iam::aws:policy/AmazonEKSClusterPolicy

terraform import aws_iam_role_policy_attachment.eks_worker_node_policy \
  namegen-dev-eks-node-role/arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy

terraform import aws_iam_role_policy_attachment.github_actions_admin_starter \
  namegen-dev-github-actions-role/arn:aws:iam::aws:policy/AdministratorAccess
```

After importing, review a Terraform plan before allowing the normal GitHub Actions workflow to continue with apply. The expected result should be either no changes or only intentional changes from the current Terraform configuration.

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

The `gp3` StorageClass uses the EKS Auto Mode block storage provisioner:

```text
ebs.csi.eks.amazonaws.com
```

Terraform enables EKS Auto Mode block storage with `storage_config`, so no separate standard EBS CSI add-on, IRSA role, or manual AWS Console configuration is required for this project.

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

Do not delete the S3 state bucket or DynamoDB lock table before running `terraform destroy`. Terraform needs the remote state to know which AWS resources belong to this project.

## 12. Troubleshooting

Common checks:

- If AWS authentication fails, verify `AWS_GITHUB_ACTIONS_ROLE_ARN` exists in GitHub repository secrets.
- If OIDC authentication fails, verify the IAM role trust policy allows the repository and `main` branch.
- If Terraform cannot create resources, verify the bootstrap role has the required AWS permissions.
- If Terraform cannot initialize, verify the default backend values or custom GitHub Actions variables for `TF_STATE_BUCKET`, `TF_STATE_KEY`, and `TF_LOCK_TABLE`.
- If Terraform reports a state lock, check the DynamoDB lock table and confirm no other workflow run is active.
- If infrastructure already exists but Terraform wants to recreate it, verify the workflow is using the same S3 backend bucket and state key as previous runs.
- If Terraform reports that ECR or IAM resources already exist, import the valid existing resources into the S3-backed Terraform state instead of recreating them.
- If the image cannot be pulled, verify the image was pushed to ECR and the EKS nodes can read from ECR.
- If MongoDB does not start, check the StatefulSet, PVC, and events in the `namegen` namespace.
- If the MongoDB PVC stays pending with `provisioner is not supported`, verify the `gp3` StorageClass uses `ebs.csi.eks.amazonaws.com` for EKS Auto Mode.
- If the application cannot connect to MongoDB, verify:

  ```text
  MONGODB_URL=mongodb://genuser:password@mongodb/namegen
  ```

- If the LoadBalancer address is empty, wait a few minutes and check:

  ```bash
  kubectl -n namegen get service namegen
  kubectl -n namegen get events --sort-by=.lastTimestamp
  ```
