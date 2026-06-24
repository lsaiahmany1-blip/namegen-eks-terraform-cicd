# NameGen EKS Terraform CI/CD

Project #3 starter repository for deploying the Red Hat NameGen application to AWS EKS Auto Mode using Terraform, Kubernetes manifests, and GitHub Actions.

## Architecture

- GitHub Actions is the primary orchestrator.
- Terraform provisions AWS infrastructure.
- AWS EKS Auto Mode runs the Kubernetes workloads.
- Amazon ECR stores the NameGen container image.
- Kubernetes manifests deploy the application and MongoDB.
- The application is exposed through an AWS Network Load Balancer.
- MongoDB runs as a StatefulSet with persistent storage.

## Source Application

The application source was copied from:

https://github.com/redhat-developer-demos/namegen

This repository keeps the application source files in the repository root as required by the assignment.

## Repository Structure

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

## Required Application Configuration

The Kubernetes deployment sets:

```text
MONGODB_URL=mongodb://genuser:password@mongodb/namegen
```

MongoDB uses:

```text
mongodb:3.6
```

## One-Time Setup

Manual work is limited to the mandatory AWS and GitHub bootstrap needed before GitHub Actions can authenticate to AWS. After this setup, the intended flow is fully automated:

```text
GitHub Actions -> Terraform apply -> EKS Auto Mode + ECR -> Docker build/push -> kubectl apply
```

### Required GitHub Secret

Create this repository secret before running the workflow:

```text
AWS_GITHUB_ACTIONS_ROLE_ARN
```

The value must be the ARN of an AWS IAM role that GitHub Actions can assume using OIDC.

### Why A Bootstrap Role Is Required

There is a real first-run circular dependency:

- `deploy.yml` needs `AWS_GITHUB_ACTIONS_ROLE_ARN` before it can authenticate to AWS.
- Terraform runs inside `deploy.yml`.
- Terraform currently defines the project-managed GitHub Actions OIDC role and outputs `github_actions_role_arn`.

Because GitHub Actions needs an AWS role before Terraform can run, the very first AWS authentication role cannot be created by the same workflow run that depends on it. A one-time bootstrap IAM role is therefore required.

After Terraform creates the project-managed role, you may optionally update the GitHub secret `AWS_GITHUB_ACTIONS_ROLE_ARN` to the Terraform output `github_actions_role_arn`.

### Minimum Manual Steps

1. In AWS, create or confirm the GitHub Actions OIDC identity provider.
2. In AWS, create one bootstrap IAM role trusted by this repository and branch.
3. Copy the bootstrap role ARN.
4. In GitHub, create the repository secret `AWS_GITHUB_ACTIONS_ROLE_ARN` with that ARN.
5. In GitHub, create or confirm the repository variable `AWS_REGION`, for example `us-east-1`.

No Kubernetes deployment, Docker build, ECR push, EKS creation, or application deployment should be done manually.

## GitHub Actions OIDC Bootstrap Review

The workflow uses GitHub Actions OIDC authentication here:

```yaml
permissions:
  id-token: write
  contents: read
```

```yaml
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_GITHUB_ACTIONS_ROLE_ARN }}
    aws-region: ${{ env.AWS_REGION }}
```

Because `deploy.yml` reads `AWS_GITHUB_ACTIONS_ROLE_ARN` before running Terraform, the bootstrap role is mandatory one-time setup and does not violate the project rule. The manual step exists only to let GitHub Actions become the primary orchestrator.

### Required One-Time AWS Setup

Create or confirm an IAM OIDC identity provider for GitHub Actions:

```text
Provider URL: https://token.actions.githubusercontent.com
Audience: sts.amazonaws.com
```

Create a bootstrap IAM role trusted by this repository and branch. The trust relationship must allow GitHub Actions from this repository to call `sts:AssumeRoleWithWebIdentity`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<AWS_ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:lsaiahmany1-blip/namegen-eks-terraform-cicd:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

For this starter project, the bootstrap role needs enough permissions for the workflow to run Terraform and then build/deploy:

- Create and manage VPC networking resources
- Create and manage EKS Auto Mode resources
- Create and manage ECR resources
- Create and manage IAM roles, policies, and OIDC resources used by the project
- Update kubeconfig and deploy Kubernetes manifests

For a class project, `AdministratorAccess` may be used temporarily for the bootstrap role if your instructor allows it. For a production-style submission, replace it with least-privilege IAM permissions.

### How To Get The Role ARN

After creating the bootstrap IAM role, copy its ARN from the AWS IAM console. It will look like:

```text
arn:aws:iam::<AWS_ACCOUNT_ID>:role/<BOOTSTRAP_ROLE_NAME>
```

If using the AWS CLI, run:

```bash
aws iam get-role --role-name <BOOTSTRAP_ROLE_NAME> --query 'Role.Arn' --output text
```

### How To Create The GitHub Secret

In GitHub:

1. Open the repository `lsaiahmany1-blip/namegen-eks-terraform-cicd`.
2. Go to `Settings` -> `Secrets and variables` -> `Actions`.
3. Choose `New repository secret`.
4. Name the secret `AWS_GITHUB_ACTIONS_ROLE_ARN`.
5. Paste the bootstrap role ARN as the value.
6. Save the secret.

Also create or confirm the repository variable:

```text
AWS_REGION=us-east-1
```

### OIDC Verification

The workflow is configured correctly for OIDC because:

- It grants `id-token: write` permission.
- It uses `aws-actions/configure-aws-credentials@v4`.
- It passes `role-to-assume` from `AWS_GITHUB_ACTIONS_ROLE_ARN`.
- The IAM trust policy limits access to this repository and the `main` branch.
- It does not use long-lived AWS access keys in the workflow.

### Architecture Verification

The documented workflow still follows the required Project #3 architecture:

```text
GitHub Actions
  -> Terraform provisions VPC, EKS Auto Mode, ECR, IAM/OIDC
  -> Docker image is built and pushed to ECR
  -> kubectl deploys Kubernetes manifests
  -> NameGen runs on EKS Auto Mode with MongoDB and an AWS NLB service
```

This keeps GitHub Actions as the primary orchestrator and Terraform as the infrastructure provisioning layer.

### Circular Dependency Review

There is a bootstrap dependency by design:

- GitHub Actions needs `AWS_GITHUB_ACTIONS_ROLE_ARN` before it can run `terraform apply`.
- Terraform includes a project GitHub Actions OIDC role output named `github_actions_role_arn`.

Therefore, the first AWS authentication role cannot be created by the same workflow run that needs it. The required solution is the one-time bootstrap role documented above. After Terraform successfully creates the project-managed role, you may update the GitHub secret `AWS_GITHUB_ACTIONS_ROLE_ARN` to the Terraform output value `github_actions_role_arn` if you want the workflow to use the Terraform-managed role going forward.

Important: AWS allows only one IAM OIDC provider per provider URL in an account. Because this starter Terraform also defines `aws_iam_openid_connect_provider.github_actions`, a manually created bootstrap OIDC provider may need to be imported into Terraform state before the project workflow can manage it. If the provider already exists in AWS and is not in Terraform state, `terraform apply` can fail when it tries to create a duplicate provider.

For a clean first run, use one of these bootstrap approaches:

- Create the bootstrap OIDC provider and role once, then import the provider and role into Terraform state before allowing Terraform to manage them.
- Keep the bootstrap role outside this Terraform project and update the Terraform code later to reference the existing OIDC provider instead of creating a new one.

The current documented requirement is still valid: the repository secret `AWS_GITHUB_ACTIONS_ROLE_ARN` must exist before `deploy.yml` can authenticate to AWS.

### Recommended Follow-Up

Keep the bootstrap role as narrow as possible. The current Terraform starter attaches broad permissions to the project-managed GitHub Actions role for simplicity, but the final project should replace broad permissions with least-privilege IAM policies once the required AWS actions are known.

## Status

This is an initial starter version only. Do not run Terraform or deploy until the files have been reviewed and completed.
