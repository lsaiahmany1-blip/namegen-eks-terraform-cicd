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
