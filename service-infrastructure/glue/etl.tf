resource "aws_s3_object" "export_data_by_year_script" {
  bucket = aws_s3_bucket.this.id
  key    = "etl_scripts/export_epb_data_by_year.py"
  source = "${path.module}/etl_scripts/export_epb_data_by_year.py"
  etag = filemd5("${path.module}/etl_scripts/export_epb_data_by_year.py")
}

resource "aws_glue_job" "export_domestic_data_by_year" {
  name     = "Export Domestic Data By Year"
  role_arn = aws_iam_role.glueServiceRole.arn
  glue_version = "5.0"

  command {
    name = "glueetl"
    python_version = "3"
    script_location = "s3://${aws_s3_bucket.this.bucket}/${aws_s3_object.export_data_by_year_script.key}"
  }

  default_arguments = {
    "--TABLE_NAME" = "domestic"
    "--S3_BUCKET" = aws_s3_bucket.this.bucket
  }
}