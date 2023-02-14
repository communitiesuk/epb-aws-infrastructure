resource "aws_ssm_parameter" "this" {
  for_each = { for index, parameter in var.parameters : parameter.name => parameter }
  name     = each.value.name
  type     = each.value.type
  value    = each.value.value

  lifecycle {
    ignore_changes = [value]
  }
}