resource "aws_cloudwatch_log_group" "log_group" {
  name              = "${var.prefix}-LogGroup"
  retention_in_days = 14
}
