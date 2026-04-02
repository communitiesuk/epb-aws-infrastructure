output "lambda_role_id" {
  value = aws_iam_role.lambda_role.id
}

output "lambda_arn" {
  value = aws_lambda_function.this.arn
}

output "lambda_name" {
  value = aws_lambda_function.this.function_name
}