output "vpc_id" {
  description = "ID of the VPC created for the project."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs of public subnets tagged for internet-facing Kubernetes load balancers."
  value       = values(aws_subnet.public)[*].id
}

output "private_subnet_ids" {
  description = "IDs of private subnets used by the EKS Auto Mode cluster."
  value       = values(aws_subnet.private)[*].id
}

output "nat_gateway_id" {
  description = "ID of the NAT Gateway used for private subnet outbound access."
  value       = aws_nat_gateway.this.id
}

output "cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint."
  value       = aws_eks_cluster.this.endpoint
}

output "ecr_repository_url" {
  description = "ECR repository URL for the NameGen container image."
  value       = aws_ecr_repository.namegen.repository_url
}

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions OIDC authentication."
  value       = aws_iam_role.github_actions.arn
}
