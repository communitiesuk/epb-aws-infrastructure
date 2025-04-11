resource "aws_sns_topic" "this" {
  name = "${local.resource_name}-notifications"
}


