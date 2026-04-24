output "etl_job_name" {
  value = aws_glue_job.this.name
}

output "etl_job_arn" {
  value = aws_glue_job.this.arn
}
