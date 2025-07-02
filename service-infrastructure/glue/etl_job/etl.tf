resource "aws_glue_job" "this" {
  name         = var.job_name
  role_arn     = var.role_arn
  glue_version = var.glue_version
  connections  = var.glue_connector
  command {
    name            = "glueetl"
    python_version  = var.python_version
    script_location = "s3://${var.bucket_name}/${aws_s3_object.this.key}"
  }
  default_arguments = var.arguments

}

resource "aws_glue_trigger" "scheduled_trigger" {
  count  = var.trigger_name != null ? 1 : 0
  name = var.trigger_name
  schedule = var.schedule
  type = "SCHEDULED"
  description = var.trigger_description
  actions {
    job_name = aws_glue_job.this.name
  }
  enabled = true
  start_on_creation = true
}

