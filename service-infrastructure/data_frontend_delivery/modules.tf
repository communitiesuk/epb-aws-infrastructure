module "collect_data_queue" {
  source = "./sqs"
  prefix = var.prefix
  queue_name = "delivery"
  lambda_role_id = aws_iam_role.lambda_role.id
}

module "send_data_queue" {
  source = "./sqs"
  prefix = var.prefix
  queue_name = "send"
  lambda_role_id = aws_iam_role.lambda_role.id
}