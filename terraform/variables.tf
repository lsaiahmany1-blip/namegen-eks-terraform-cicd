variable "aws_region" {
  description = "AWS region for the EKS cluster and ECR repository."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for AWS resource names."
  type        = string
  default     = "namegen"
}

variable "environment" {
  description = "Environment label for resource tags."
  type        = string
  default     = "dev"
}

variable "cluster_version" {
  description = "EKS Kubernetes control plane version."
  type        = string
  default     = "1.30"
}

variable "vpc_id" {
  description = "Existing VPC ID for the EKS cluster. Replace during final implementation."
  type        = string
  default     = ""
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for EKS. Replace during final implementation."
  type        = list(string)
  default     = []
}

variable "github_repository" {
  description = "GitHub repository allowed to assume the deploy role, in owner/repo format."
  type        = string
  default     = "lsaiahmany1-blip/namegen-eks-terraform-cicd"
}

variable "github_branch" {
  description = "GitHub branch allowed to assume the deploy role."
  type        = string
  default     = "main"
}
