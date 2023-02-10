output "ecs_cluster_id" {
  value = aws_ecs_cluster.this.id
}

output "iam_policy_rds_arn" {
  value       = aws_iam_policy.rds.arn
  description = "IAM policy allowing full access to RDS"
}