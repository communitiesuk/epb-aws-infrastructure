data "aws_iam_policy_document" "s3_role_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = [
      aws_s3_bucket.epbr_s3_terraform_state.arn,
      "${aws_s3_bucket.epbr_s3_terraform_state.arn}/*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:listBucket"
    ]
    resources = [
      aws_s3_bucket.epbr_s3_terraform_state.arn
    ]
  }
}

data "aws_iam_policy_document" "dynamo_db_policy" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem"
    ]
    resources = [
      aws_dynamodb_table.epbr_dynamo_terraform_state.arn
    ]
  }

}