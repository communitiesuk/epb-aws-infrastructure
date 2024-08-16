data "aws_iam_policy_document" "event_bridge_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "pipeline_event_role" {
  name               = "fluentbit-image-pipeline-event-bridge-role"
  assume_role_policy = data.aws_iam_policy_document.event_bridge_role.json
}

data "aws_iam_policy_document" "pipeline_event_role_policy" {
  statement {
    sid       = ""
    actions   = ["codepipeline:StartPipelineExecution"]
    resources = [aws_codepipeline.fluentbit_image_codepipeline.arn]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "pipeline_event_role_policy" {
  name   = "fluentbit-image-codepipeline-event-role-policy"
  policy = data.aws_iam_policy_document.pipeline_event_role_policy.json
}

resource "aws_iam_role_policy_attachment" "pipeline_event_role_attach_policy" {
  role       = aws_iam_role.pipeline_event_role.name
  policy_arn = aws_iam_policy.pipeline_event_role_policy.arn
}
