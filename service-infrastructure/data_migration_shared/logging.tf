resource "aws_cloudwatch_log_group" "this" {
  name = "${var.prefix}-lg"

  tags = {
    Application = var.prefix
  }
}