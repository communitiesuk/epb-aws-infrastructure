resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${aws_lambda_function.collect_user_filtered_data.function_name}"
  retention_in_days = 90
}