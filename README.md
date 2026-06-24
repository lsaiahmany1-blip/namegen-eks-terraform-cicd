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
├── .github/
│   └── workflows/
│       └── deploy.yml
├── terraform/
│   ├── versions.tf
│   ├── providers.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── main.tf
├── kubernetes/
│   ├── namespace.yaml
│   ├── mongodb-secret.yaml
│   ├── mongodb-service.yaml
│   ├── mongodb-statefulset.yaml
│   ├── namegen-deployment.yaml
│   ├── namegen-service.yaml
│   └── kustomization.yaml
├── diagrams/
│   └── architecture.drawio
├── screenshots/
│   └── README.md
├── Dockerfile
├── README.md
└── application source code files
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

## One-Time Setup Still Required

Before the workflow can run successfully, complete the mandatory setup items:

- Configure AWS credentials and permissions for Terraform bootstrap.
- Decide whether Terraform should create networking or use existing VPC/subnets.
- Set the GitHub Actions secret `AWS_GITHUB_ACTIONS_ROLE_ARN` after the role exists.
- Set or confirm the GitHub Actions variable `AWS_REGION`.
- Review Terraform IAM permissions and replace starter broad permissions with least privilege.

## Status

This is an initial starter version only. Do not run Terraform or deploy until the files have been reviewed and completed.
