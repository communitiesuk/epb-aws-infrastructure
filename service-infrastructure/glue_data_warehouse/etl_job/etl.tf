resource "aws_glue_job" "this" {
  name              = var.job_name
  role_arn          = var.role_arn
  glue_version      = var.glue_version
  connections       = var.glue_connector
  worker_type       = var.worker_type
  number_of_workers = 10
  command {
    name            = "glueetl"
    python_version  = var.python_version
    script_location = "s3://${var.bucket_name}/etl_scripts/${var.script_file_name}"
  }
  default_arguments = merge(
    var.arguments,
    var.extra_py_files != "" ? { "--extra-py-files" = var.extra_py_files } : {}
  )
}

