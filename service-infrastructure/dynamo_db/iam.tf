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