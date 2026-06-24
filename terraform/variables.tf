variable "aws_region" {
  description = "AWS region for the EKS cluster, ECR repository, and networking resources."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for AWS resource names."
  type        = string
  default     = "namegen"
}

variable "environment" {
  description = "Environment label for resource names and tags."
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the project VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones used for public and private subnets."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least two availability zones are required for EKS."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets."
  type        = list(string)
  default     = ["10.0.0.0/20", "10.0.16.0/20"]

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "At least two public subnet CIDR blocks are required."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets used by the EKS Auto Mode cluster."
  type        = list(string)
  default     = ["10.0.128.0/20", "10.0.144.0/20"]

  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "At least two private subnet CIDR blocks are required."
  }
}

variable "cluster_version" {
  description = "EKS Kubernetes control plane version."
  type        = string
  default     = "1.30"
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
