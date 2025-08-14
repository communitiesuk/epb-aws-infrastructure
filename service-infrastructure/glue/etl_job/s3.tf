resource "aws_s3_object" "this" {
  bucket = var.bucket_name
  key    = "etl_scripts/${var.script_file_name}${var.suffix}"
  source = "${var.scripts_module}/etl_scripts/${var.script_file_name}"
  etag   = filemd5("${var.scripts_module}/etl_scripts/${var.script_file_name}")
}
