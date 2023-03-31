resource "aws_iam_user" "cloudwatch_user" {
  name = "logit_user"
}

resource "aws_iam_user_policy_attachment" "logit_user_s3" {
  user       = aws_iam_user.cloudwatch_user.name
  policy_arn = aws_iam_policy.s3_logs_read_access.arn
}

resource "aws_iam_user_policy_attachment" "logit_user_cloudwatch" {
  user       = aws_iam_user.cloudwatch_user.name
  policy_arn = aws_iam_policy.cloudwatch_logs_access.arn
}
