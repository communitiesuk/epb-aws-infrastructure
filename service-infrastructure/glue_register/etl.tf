module "update_scottish_created_at_date" {
  source           = "./etl_job"
  bucket_name      = var.storage_bucket
  glue_connector   = [aws_glue_connection.this.name]
  job_name         = "Update Scottish CreatedAt date"
  role_arn         = aws_iam_role.glueServiceRole.arn
  script_file_name = "update_scottish_created_at_date.py"
  scripts_module   = path.module
  arguments = {
    "--DB_NAME"                   = var.db_name
    "--DB_HOST"                   = var.db_instance
    "--DB_PORT"                   = var.db_port
    "--INPUT_S3_PATH"             = ""
    "--GLUE_CONNECTION_NAME"      = aws_glue_connection.this.name
    "--additional-python-modules" = var.python_modules
  }
}

module "update_scottish_address_ids" {
  source           = "./etl_job"
  bucket_name      = var.storage_bucket
  glue_connector   = [aws_glue_connection.this.name]
  job_name         = "Update Scottish address_ids"
  role_arn         = aws_iam_role.glueServiceRole.arn
  script_file_name = "update_scottish_address_ids.py"
  scripts_module   = path.module
  arguments = {
    "--DB_NAME"                   = var.db_name
    "--DB_HOST"                   = var.db_instance
    "--DB_PORT"                   = var.db_port
    "--INPUT_S3_PATH"             = ""
    "--GLUE_CONNECTION_NAME"      = aws_glue_connection.this.name
    "--additional-python-modules" = var.python_modules
  }
}

module "insert_scottish_green_deals" {
  source           = "./etl_job"
  bucket_name      = var.storage_bucket
  glue_connector   = [aws_glue_connection.this.name]
  job_name         = "Insert Scottish green deals"
  role_arn         = aws_iam_role.glueServiceRole.arn
  script_file_name = "insert_scottish_green_deals.py"
  scripts_module   = path.module
  arguments = {
    "--DB_NAME"                   = var.db_name
    "--DB_HOST"                   = var.db_instance
    "--DB_PORT"                   = var.db_port
    "--INPUT_S3_PATH_GDPlans"     = ""
    "--INPUT_S3_PATH_GD_P"        = ""
    "--INPUT_S3_PATH_GDPM"        = ""
    "--INPUT_S3_PATH_GDPS"        = ""
    "--INPUT_S3_PATH_GDPDC"       = ""
    "--GLUE_CONNECTION_NAME"      = aws_glue_connection.this.name
    "--RANDOMISE_PLAN_IDS"        = ""
    "--additional-python-modules" = var.python_modules
  }
}

module "update_scottish_status" {
  source           = "./etl_job"
  bucket_name      = var.storage_bucket
  glue_connector   = [aws_glue_connection.this.name]
  job_name         = "Update Scottish Statuses"
  role_arn         = aws_iam_role.glueServiceRole.arn
  script_file_name = "update_scottish_status.py"
  scripts_module   = path.module
  arguments = {
    "--DB_NAME"                   = var.db_name
    "--DB_HOST"                   = var.db_instance
    "--DB_PORT"                   = var.db_port
    "--INPUT_S3_PATH"             = ""
    "--GLUE_CONNECTION_NAME"      = aws_glue_connection.this.name
    "--additional-python-modules" = var.python_modules
  }
}
