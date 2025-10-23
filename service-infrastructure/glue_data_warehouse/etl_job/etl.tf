resource "aws_glue_job" "this" {
  name         = var.job_name
  role_arn     = var.role_arn
  glue_version = var.glue_version
  connections  = var.glue_connector
  worker_type  = var.worker_type
  command {
    name            = "glueetl"
    python_version  = var.python_version
    script_location = "s3://${var.bucket_name}/${aws_s3_object.this.key}"
  }
  default_arguments = var.arguments
}

