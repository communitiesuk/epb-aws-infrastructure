data "aws_iam_policy_document" "this" {
  statement {
    effect = "Allow"
    actions = [
      "codepipeline:ListPipelines",
      "codepipeline:GetPipelineState",

    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObjectAcl",
      "s3:PutObject"

    ]
    resources = [
      "arn:aws:s3:::${var.bucket}/${var.key}",
    ]

  }

  statement {
    effect = "Allow"
    actions = [
      "logs:*",
    ]
    resources = ["*"]
  }

}

data "aws_iam_policy_document" "ccxml_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"

      identifiers = [
        "lambda.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "cc-xml-role"
  assume_role_policy = data.aws_iam_policy_document.ccxml_assume_role_policy.json
}

resource "aws_iam_role_policy" "this" {
  name   = "cc-xml-policy"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.this.json
}

resource "aws_lambda_permission" "this" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.this.arn
}
