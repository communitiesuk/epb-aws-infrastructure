data "aws_arn" "athena_workgroup" {
  arn = var.athena_workgroup_arn
}

data "archive_file" "collect_user_filtered_data" {
  type        = "zip"
  source_dir  = "${path.module}/functions/collect-user-filtered-data"
  output_path = "collect_user_filtered_data.zip"
}

resource "aws_lambda_function" "collect_user_filtered_data" {
  description   = "lambda to collect user filtered data"
  filename      = data.archive_file.collect_user_filtered_data.output_path
  function_name = "${var.prefix}-collect-user-filtered-data"
  role          = aws_iam_role.lambda_role.arn

  runtime = "python3.12"
  handler = "index.lambda_handler"

  source_code_hash = data.archive_file.collect_user_filtered_data.output_base64sha256

  environment {
    variables = {
      ATHENA_TABLE     = "domestic",
      ATHENA_DATABASE  = var.glue_catalog_name
      ATHENA_WORKGROUP = basename(data.aws_arn.athena_workgroup.resource)
    }
  }
}
