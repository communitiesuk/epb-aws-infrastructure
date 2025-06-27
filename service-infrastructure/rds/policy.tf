locals {
  policy_name = var.name_suffix == null ? "${var.prefix}-RDSAccess" : "${var.prefix}-RDSAccess-V2"
}

resource "aws_iam_policy" "rds" {
  name        = local.policy_name
  description = "Policy that allows full access to RDS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "rds:*"
        Resource = aws_db_instance.postgres_rds.arn
      }
    ]
  })

  lifecycle {
    prevent_destroy = true
  }
}
