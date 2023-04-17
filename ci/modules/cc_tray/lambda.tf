
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/${var.app_name}"
  output_path = "${path.module}/${var.app_name}.zip"

}


resource "aws_lambda_function" "this" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    =  var.app_name
  handler          =  var.app_name
  description      = "Handler that responds to CodePipeline events by updating a CCTray XML feed"
  memory_size      = 128
  timeout          = 20
  runtime          = "go1.x"
  source_code_hash =  data.archive_file.lambda_zip.output_base64sha256
  role             = aws_iam_role.this.arn

  environment {
    variables = {
      BUCKET = var.bucket
      KEY    = var.key
    }
  }
}
