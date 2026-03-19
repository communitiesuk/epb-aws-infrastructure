resource "aws_sqs_queue" "dead_letter_queue" {
  name              = "${local.resource_name}-dead-letter-queue"
  kms_master_key_id = var.kms_key_arn
}

resource "aws_sqs_queue" "this" {
  name              = "${local.resource_name}-queue"
  kms_master_key_id = var.kms_key_arn

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter_queue.arn
    maxReceiveCount     = 4
  })
  visibility_timeout_seconds = var.lambda_timeout
}

resource "aws_sqs_queue_redrive_allow_policy" "terraform_queue_redrive_allow_policy" {
  queue_url = aws_sqs_queue.dead_letter_queue.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.this.arn]
  })
}
