output "glue_security_group_id" {
  value = aws_security_group.glue_security_group.id
}

output "glue_s3_bucket_read_policy_arn" {
  value = aws_iam_policy.s3_bucket_read.arn
}

output "athena_workgroup_arn" {
  value = aws_athena_workgroup.this.arn
}

output "glue_catalog_name" {
  value = aws_glue_catalog_database.this.name
}