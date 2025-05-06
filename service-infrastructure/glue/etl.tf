module "create_domestic_etl" {
  source           = "./etl_job"
  bucket_name      = aws_s3_bucket.this.bucket
  glue_connector   = [aws_glue_connection.this.name]
  job_name         = "Create domestic catalog table"
  role_arn         = aws_iam_role.glueServiceRole.arn
  script_file_name = "create_data_catalog.py"
  scripts_module   = path.module
  arguments = {
    "--DATABASE_NAME"      = aws_glue_catalog_database.this.name
    "--CATALOG_TABLE_NAME" = "domestic"
    "--S3_BUCKET"          = aws_s3_bucket.this.bucket
    "--CONNECTION_NAME"    = aws_glue_connection.this.name
    "--DB_TABLE_NAME"      = "mvw_domestic_search"
  }
}

module "create_domestic_rr_etl" {
  source           = "./etl_job"
  bucket_name      = aws_s3_bucket.this.bucket
  glue_connector   = [aws_glue_connection.this.name]
  job_name         = "Create domestic rr catalog table"
  role_arn         = aws_iam_role.glueServiceRole.arn
  script_file_name = "create_data_catalog.py"
  scripts_module   = path.module
  arguments = {
    "--DATABASE_NAME"      = aws_glue_catalog_database.this.name
    "--CATALOG_TABLE_NAME" = "domestic_rr"
    "--S3_BUCKET"          = aws_s3_bucket.this.bucket
    "--CONNECTION_NAME"    = aws_glue_connection.this.name
    "--DB_TABLE_NAME"      = "mvw_domestic_rr_search"
  }
}

module "export_domestic_data_by_year" {
  source           = "./etl_job"
  bucket_name      = aws_s3_bucket.this.bucket
  job_name         = "Export Domestic Data By Year"
  role_arn         = aws_iam_role.glueServiceRole.arn
  script_file_name = "export_by_year.py"
  scripts_module   = path.module
  arguments = {
    "--DATABASE_NAME" = aws_glue_catalog_database.this.name
    "--TABLE_NAME"    = "domestic"
    "--TABLE_NAME_RR" = "domestic_rr"
    "--S3_BUCKET"     = var.output_bucket_name
  }
}
