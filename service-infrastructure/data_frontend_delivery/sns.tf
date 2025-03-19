resource "aws_sns_topic" "this" {
  name = "${var.prefix}-data-frontend-delivery-notifications"
}