locals {
  iceberg_conf = "spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions --conf spark.sql.catalog.glue_catalog=org.apache.iceberg.spark.SparkCatalog --conf spark.sql.catalog.glue_catalog.catalog-impl=org.apache.iceberg.aws.glue.GlueCatalog --conf spark.sql.catalog.glue_catalog.io-impl=org.apache.iceberg.aws.s3.S3FileIO --conf spark.sql.catalog.glue_catalog.warehouse=file:///tmp/spark-warehouse"
}


module "populate_domestic_etl" {
  source           = "./etl_job"
  bucket_name      = aws_s3_bucket.this.bucket
  glue_connector   = [aws_glue_connection.this.name]
  job_name         = "Populate domestic catalog"
  role_arn         = aws_iam_role.glueServiceRole.arn
  script_file_name = "populate_iceberg_catalog.py"
  scripts_module   = path.module
  arguments = {
    "--DATABASE_NAME"             = aws_glue_catalog_database.this.name
    "--CATALOG_TABLE_NAME"        = "domestic"
    "--S3_BUCKET"                 = aws_s3_bucket.this.bucket
    "--CONNECTION_NAME"           = aws_glue_connection.this.name
    "--DB_TABLE_NAME"             = "mvw_domestic_search"
    "--COLUMNS"                   = templatefile("${path.module}/table_definitions/domestic.txt", {})
    "--additional-python-modules" = "boto3==1.38.43"
  }
}

module "populate_domestic_rr_etl" {
  source           = "./etl_job"
  bucket_name      = aws_s3_bucket.this.bucket
  glue_connector   = [aws_glue_connection.this.name]
  job_name         = "Populate domestic rr catalog"
  role_arn         = aws_iam_role.glueServiceRole.arn
  script_file_name = "populate_iceberg_catalog.py"
  scripts_module   = path.module
  arguments = {
    "--DATABASE_NAME"             = aws_glue_catalog_database.this.name
    "--CATALOG_TABLE_NAME"        = "domestic_rr"
    "--S3_BUCKET"                 = aws_s3_bucket.this.bucket
    "--CONNECTION_NAME"           = aws_glue_connection.this.name
    "--DB_TABLE_NAME"             = "mvw_domestic_rr_search"
    "--COLUMNS"                   = templatefile("${path.module}/table_definitions/domestic_rr.txt", {})
    "--additional-python-modules" = "boto3==1.38.43"

  }
}


module "populate_json_documents_etl" {
  count            = local.number_of_jobs
  source           = "./etl_job"
  bucket_name      = aws_s3_bucket.this.bucket
  glue_connector   = [aws_glue_connection.this.name]
  job_name         = "Populate json documents catalog ${local.catalog_start_year + count.index}"
  role_arn         = aws_iam_role.glueServiceRole.arn
  script_file_name = "populate_iceberg_catalog.py"
  scripts_module   = path.module
  suffix           = ".json_documents_${local.catalog_start_year + count.index}"
  arguments = {
    "--DATABASE_NAME"             = aws_glue_catalog_database.this.name
    "--CATALOG_TABLE_NAME"        = "domestic_json_documents"
    "--S3_BUCKET"                 = aws_s3_bucket.this.bucket
    "--CONNECTION_NAME"           = aws_glue_connection.this.name
    "--DB_TABLE_NAME"             = "vw_domestic_documents_${local.catalog_start_year + count.index}"
    "--COLUMNS"                   = templatefile("${path.module}/table_definitions/json_documents.txt", {})
    "--additional-python-modules" = "boto3==1.38.43"
  }
}

module "delete_iceberg_data" {
  source         = "./etl_job"
  glue_connector = [aws_glue_connection.this.name]
  arguments = {
    "--CONNECTION_NAME"  = aws_glue_connection.this.name
    "--DATABASE_NAME"    = aws_glue_catalog_database.this.name
    "--datalake-formats" = "iceberg"
    "--conf"             = local.iceberg_conf
  }
  bucket_name      = aws_s3_bucket.this.bucket
  job_name         = "Delete Iceberg data"
  role_arn         = aws_iam_role.glueServiceRole.arn
  script_file_name = "delete_data.py"
  scripts_module   = path.module
}

module "insert_domestic_iceberg_data" {
  source         = "./etl_job"
  glue_connector = [aws_glue_connection.this.name]
  arguments = {
    "--CONNECTION_NAME"        = aws_glue_connection.this.name
    "--DATABASE_NAME"          = aws_glue_catalog_database.this.name
    "--CATALOG_TABLE_NAME"     = "domestic"
    "--SOURCE_VIEW_TABLE_NAME" = "vw_domestic_yesterday"
    "--conf"                   = local.iceberg_conf
  }
  bucket_name      = aws_s3_bucket.this.bucket
  job_name         = "Insert domestic iceberg data"
  role_arn         = aws_iam_role.glueServiceRole.arn
  script_file_name = "insert_data.py"
  scripts_module   = path.module
}

module "insert_domestic_rr_iceberg_data" {
  source         = "./etl_job"
  glue_connector = [aws_glue_connection.this.name]
  arguments = {
    "--CONNECTION_NAME"        = aws_glue_connection.this.name
    "--DATABASE_NAME"          = aws_glue_catalog_database.this.name
    "--CATALOG_TABLE_NAME"     = "domestic_rr"
    "--SOURCE_VIEW_TABLE_NAME" = "vw_domestic_rr_yesterday"
    "--conf"                   = local.iceberg_conf
  }
  bucket_name      = aws_s3_bucket.this.bucket
  job_name         = "Insert domestic rr iceberg data"
  role_arn         = aws_iam_role.glueServiceRole.arn
  script_file_name = "insert_data.py"
  scripts_module   = path.module
}

module "export_domestic_data_by_year" {
  source           = "./etl_job"
  bucket_name      = aws_s3_bucket.this.bucket
  job_name         = "Export domestic data by year to S3"
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

module "export_json_domestic_data_by_year" {
  source           = "./etl_job"
  bucket_name      = aws_s3_bucket.this.bucket
  job_name         = "Export JSON domestic data by year to S3"
  role_arn         = aws_iam_role.glueServiceRole.arn
  script_file_name = "export_json_by_year.py"
  scripts_module   = path.module
  arguments = {
    "--DATABASE_NAME" = aws_glue_catalog_database.this.name
    "--TABLE_NAME"    = "domestic_json_documents"
    "--S3_BUCKET"     = var.output_bucket_name
  }
}