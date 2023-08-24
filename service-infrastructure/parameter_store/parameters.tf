resource "aws_ssm_parameter" "this" {
  for_each = var.parameters
  name     = each.key
  type     = each.value.type
  value    = each.value.value
  tier     = each.value.tier
}
