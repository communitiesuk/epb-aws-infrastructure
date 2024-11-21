output "parameter_arns" {
  value = { for index, parameter in aws_ssm_parameter.this : parameter.name => parameter.arn }
}



