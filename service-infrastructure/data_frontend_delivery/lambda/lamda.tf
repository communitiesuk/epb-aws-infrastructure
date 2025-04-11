data "archive_file" "this" {
  type        = "zip"
  source_dir  = "${path.module}/functions/${var.function_name}"
  output_path = "${var.output_path}.zip"
}

resource "aws_lambda_function" "this" {
  filename      = data.archive_file.this.output_path
  function_name = "${var.prefix}-${var.function_name}"
  role          = aws_iam_role.lambda_role.arn

  runtime = "python3.12"
  handler = "index.lambda_handler"

  source_code_hash = data.archive_file.this.output_base64sha256

  environment {
    variables = var.environment
  }
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = var.sqs_arn
  function_name    = aws_lambda_function.this.arn
  batch_size       = 1
  enabled          = true
}
