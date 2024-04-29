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

resource "aws_iam_policy" "rds-read-only" {
  count       = var.read_only_policy ? 1 : 0
  name        = "${var.prefix}-RDSAccess-read-only"
  description = "Policy that allows read only access to RDS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["rds:Describe*",
          "rds:ListTagsForResource",
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeVpcAttribute",
          "ec2:DescribeVpcs"
        ]
        Resource = aws_rds_cluster.this.arn
      }
    ]
  })

  lifecycle {
    prevent_destroy = true
  }
}