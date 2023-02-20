resource "aws_ssm_parameter" "this" {
  for_each = var.parameters

  name  = each.key
  type  = each.value
  value = "placeholder" // These values should be updated manually or via CI/CD pipeline

  lifecycle {
    ignore_changes = [value]
  }
}