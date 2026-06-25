# Screenshots

This folder contains the final project screenshots used to demonstrate that Project #3 was implemented with GitHub Actions, Terraform, EKS Auto Mode, Kubernetes, MongoDB persistence, and AWS Network Load Balancer access.

| File | What it demonstrates |
| --- | --- |
| `01-github-repository.png` | Repository root with the application source code, Dockerfile, Terraform folder, Kubernetes folder, diagrams folder, and screenshots folder. |
| `02-github-actions-success.png` | GitHub Actions workflow list showing successful automated CI/CD runs. |
| `03-workflow-validation.png` | Successful workflow validation output showing Kubernetes pods, PVC, service, LoadBalancer hostname, and StorageClass details. |
| `04-eks-cluster.png` | AWS EKS console showing the Terraform-created EKS cluster in `Active` status. |
| `05-loadbalancer-application.png` | NameGen application opened through the AWS Network Load Balancer and saving names successfully. |
| `06-vpc.png` | AWS VPC console showing the Terraform-created project VPC resources. |
| `07-terraform-folder.png` | Terraform folder in GitHub with backend, provider, variables, outputs, and main infrastructure files. |

## Review Notes

- Duplicate screenshots were not added. The repository root screenshot already covers the project structure, so a separate duplicate project-structure screenshot was not kept.
- Recommended additional screenshot before final submission: an Amazon ECR repository screenshot showing the pushed NameGen Docker image tag.
