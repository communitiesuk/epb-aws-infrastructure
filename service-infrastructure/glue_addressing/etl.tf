module "load_ngd_csvs_into_s3_etl" {
  source           = "./etl_job"
  bucket_name      = var.storage_bucket
  glue_connector   = [aws_glue_connection.this.name]
  job_name         = "Load NGD CSVs into S3"
  role_arn         = aws_iam_role.glueServiceRole.arn
  script_file_name = "load-ngd-csvs-into-s3.py"
  scripts_module   = path.module
  arguments = {
    "--S3_BUCKET"       = var.storage_bucket
    "--OS_API_KEY"      = var.os_data_hub_api_key
    "--DATA_PACKAGE_ID" = var.os_data_package_id
    "--additional-python-modules" = "stream-unzip==0.0.99"
  }
}

module "import_ngd_csv_into_postgres_etl" {
  source           = "./etl_job"
  bucket_name      = var.storage_bucket
  glue_connector   = [aws_glue_connection.this.name]
  job_name         = "Import NGD CSV into Postgres"
  role_arn         = aws_iam_role.glueServiceRole.arn
  script_file_name = "import-csvs-into-postgres.py"
  scripts_module   = path.module
  arguments = {
    "--DATABASE_NAME"   = var.db_name
    "--S3_BUCKET"       = var.storage_bucket
    "--CONNECTION_NAME" = aws_glue_connection.this.name
    "--DB_TABLE_NAME"   = "addressing_temp"
  }
}