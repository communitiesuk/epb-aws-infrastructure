module "collect_data_queue" {
  source         = "./sqs"
  prefix         = var.prefix
  queue_name     = "delivery"
  lambda_role_id = module.collect_user_data_lambda.lambda_role_id
}

module "send_data_queue" {
  source         = "./sqs"
  prefix         = var.prefix
  queue_name     = "send"
  lambda_role_id = module.send_user_data_lambda.lambda_role_id
}

data "aws_arn" "athena_workgroup" {
  arn = var.athena_workgroup_arn
}

module "collect_user_data_lambda" {
  source        = "./lambda"
  prefix        = var.prefix
  function_name = "collect-user-filtered-data"
  output_file   = "collect_user_filtered_data.zip"
  environment = {
    ATHENA_TABLE     = "domestic",
    ATHENA_DATABASE  = var.glue_catalog_name
    ATHENA_WORKGROUP = basename(data.aws_arn.athena_workgroup.resource)
  }
  sqs_arn = module.collect_data_queue.sqs_queue_arn
}

module "send_user_data_lambda" {
  source        = "./lambda"
  prefix        = var.prefix
  function_name = "send-user-requested-data"
  output_file   = "send_user_requested_data.zip"
  environment = {
    NOTIFY_DATA_API_KEY              = var.parameters["NOTIFY_DATA_API_KEY"],
    NOTIFY_DATA_DOWNLOAD_TEMPLATE_ID = var.parameters["NOTIFY_DATA_DOWNLOAD_TEMPLATE_ID"],
  }
  sqs_arn = module.send_data_queue.sqs_queue_arn
}