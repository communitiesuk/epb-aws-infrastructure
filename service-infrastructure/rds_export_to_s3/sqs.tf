resource "aws_sqs_queue" "monitor_queue" {
  name = "monitor-queue"

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.monitor_dead_letter.arn
    maxReceiveCount     = 4
  })
}

resource "aws_sqs_queue" "monitor_dead_letter" {
  name = "monitor-dead-letter-queue"
}

resource "aws_sqs_queue_redrive_allow_policy" "terraform_queue_redrive_allow_policy" {
  queue_url = aws_sqs_queue.monitor_dead_letter.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.monitor_queue.arn]
  })
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