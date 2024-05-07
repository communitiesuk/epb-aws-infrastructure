resource "aws_iam_policy" "rds" {
  name        = "${var.prefix}-RDSAccess"
  description = "Policy that allows full access to RDS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "rds:*"
        Resource = aws_rds_cluster.this.arn
      }
    ]
  })

  lifecycle {
    prevent_destroy = true
  }
}

