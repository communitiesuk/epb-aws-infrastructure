
resource "aws_iam_role_policy" "athena_execution_access" {
  name = "${var.prefix}-athena-execution-access"
  role = module.collect_user_data_lambda.lambda_role_id

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "athena:StartQueryExecution",
            "athena:GetQueryExecution",
            "athena:GetQueryResults",
            "athena:GetWorkGroup",
            "athena:ListWorkGroups"
          ]
          Effect = "Allow"
          Resource = [
            var.athena_workgroup_arn
          ]
        }
      ]
  })
}

resource "aws_iam_role_policy" "glue_read_access" {
  name = "${var.prefix}-glue-read-access"
  role = module.collect_user_data_lambda.lambda_role_id

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "glue:GetTable",
            "glue:GetDatabase",
            "glue:GetPartition",
            "glue:GetCatalogImportStatus",
            "glue:BatchGetPartition",
            "glue:GetTables",
            "glue:GetDatabases"
          ]
          Effect = "Allow"
          Resource = [
            "arn:aws:glue:*:*:catalog",
            "arn:aws:glue:*:*:database/${var.glue_catalog_name}",
            "arn:aws:glue:*:*:table/${var.glue_catalog_name}/*"
          ]
        }
      ]
  })
}

resource "aws_iam_policy" "list_bucket" {
  name        = "${var.prefix}-policy-list-bucket"
  description = "Policy that allows list access to an S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
        ]
        Resource = [
          var.output_bucket_arn
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "sqs_send_message_policy" {
  name_prefix = "${var.prefix}-sqs-send-message"
  description = "Policy to allow to send messages to the SQS queue"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sqs:SendMessage",
        ],
        Effect = "Allow",
        Resource = [
          module.send_data_queue.sqs_queue_arn
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sqs_send_message_policy_attachment" {
  role       = module.collect_user_data_lambda.lambda_role_id
  policy_arn = aws_iam_policy.sqs_send_message_policy.arn
}

resource "aws_iam_role_policy_attachment" "list_bucket_policy_attachment" {
  role       = module.collect_user_data_lambda.lambda_role_id
  policy_arn = aws_iam_policy.list_bucket.arn
}

resource "aws_iam_role_policy_attachment" "glue_s3_read_policy_attachment" {
  role       = module.collect_user_data_lambda.lambda_role_id
  policy_arn = var.glue_s3_bucket_read_policy_arn
}

resource "aws_iam_role_policy_attachment" "output_s3_write_policy_attachment" {
  role       = module.collect_user_data_lambda.lambda_role_id
  policy_arn = var.output_bucket_write_policy_arn
}