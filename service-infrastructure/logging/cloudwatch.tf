resource "aws_cloudwatch_log_group" "this" {
  name = "${var.prefix}-lg"

  tags = {
    Environment = var.environment
    Application = var.prefix
  }
}