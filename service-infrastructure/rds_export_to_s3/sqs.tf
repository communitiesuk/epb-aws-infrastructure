resource "aws_sqs_queue" "monitor_queue" {
  name = "monitor-queue"
}

data "aws_iam_policy_document" "sns_to_sqs_document" {
  statement {
    sid    = "First"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.monitor_queue.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_sns_topic.exportMonitorNotifications[0].arn]
    }
  }
}

resource "aws_sqs_queue_policy" "sns_to_sqs_policy" {
  queue_url = aws_sqs_queue.monitor_queue.id
  policy    = data.aws_iam_policy_document.sns_to_sqs_document.json
}