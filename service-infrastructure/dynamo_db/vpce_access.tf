resource "aws_vpc_endpoint_policy" "dynamodb_access" {
  vpc_endpoint_id = aws_vpc_endpoint.this.id
  policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Effect" = "Allow",
        "Principal" = {
          "AWS" : var.ecs_roles
        },
        "Action" = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:Scan",
        ],

        "Resource" = aws_dynamodb_table.epb_data_credentials.arn
      }
    ]
  })
}