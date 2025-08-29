resource "aws_iam_policy" "dynamodb_write_access" {
  name        = "${var.prefix}-policy-dynamodb-write"
  description = "Policy that allows write access to an DynamoDB table only via VPC endpoint"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ]
        Resource = aws_dynamodb_table.this.arn
        Condition = {
          StringEquals = {
            "aws:sourceVpce" = aws_vpc_endpoint.this.id
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "dynamodb_read_access" {
  name        = "${var.prefix}-policy-dynamodb-read"
  description = "Policy that allows read access to an DynamoDB table only via VPC endpoint"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:Scan",
          "dynamodb:GetItem",
        ]
        Resource = aws_dynamodb_table.this.arn
        Condition = {
          StringEquals = {
            "aws:sourceVpce" = aws_vpc_endpoint.this.id
          }
        }
      },
      {
        "Effect" : "Allow",
        "Action" : "kms:Decrypt",
        "Resource" : var.kms_key_arn
      }
    ]
  })
}

resource "aws_vpc_endpoint_policy" "dynamodb_access" {
  vpc_endpoint_id = aws_vpc_endpoint.this.id
  policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Effect" = "Allow",
        "Principal" = {
          "AWS" : "*"
        },
        "Action" = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Scan",
          "dynamodb:GetItem",
        ],
        "Resource" = aws_dynamodb_table.this.arn,
        "Condition" = {
          "StringEquals" = {
            "aws:PrincipalArn" = var.ecs_roles
          }
        }
      }
    ]
  })
}

