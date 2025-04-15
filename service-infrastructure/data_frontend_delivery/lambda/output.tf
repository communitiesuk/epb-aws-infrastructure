output "lambda_role_id" {
  value = aws_iam_role.lambda_role.id
}

output "lambda_arn" {
  value = aws_lambda_function.this.arn
}