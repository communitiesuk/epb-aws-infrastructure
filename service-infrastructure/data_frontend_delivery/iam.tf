resource "aws_iam_policy" "sns_write_policy" {
  name        = "${var.prefix}-data-frontend-delivery-sns-write"
  description = "Policy that allows write access to the data_frontend sns"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sns:Publish"
        ],
        Resource = aws_sns_topic.this.arn
      }
    ]
  })
}

resource "aws_iam_role" "lambda_collect_user_filtered_data_role" {
  name = "${var.prefix}-lambda-collect-user-filtered-data-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudwatch_logs_access" {
  name = "${var.prefix}-cloudwatch-logs-access"
  role = aws_iam_role.lambda_collect_user_filtered_data_role.id

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:DescribeLogStreams",
            "logs:PutLogEvents",
            "logs:PutRetentionPolicy"
          ]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
  })
}

resource "aws_iam_role_policy" "sqs_consumer_access" {
  name = "${var.prefix}-sqs-consumer-access"
  role = aws_iam_role.lambda_collect_user_filtered_data_role.id

  policy = jsonencode(
    {
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "sqs:ReceiveMessage",
            "sqs:DeleteMessage",
            "sqs:GetQueueAttributes",
          ]
          Effect = "Allow"
          Resource = [
            aws_sqs_queue.this.arn
          ]
        }
      ]
  })
}

resource "aws_iam_role_policy" "athena_execution_access" {
  name = "${var.prefix}-athena-execution-access"
  role = aws_iam_role.lambda_collect_user_filtered_data_role.id

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
  role = aws_iam_role.lambda_collect_user_filtered_data_role.id

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

resource "aws_iam_role_policy_attachment" "glue_s3_read_policy_attachment" {
  role       = aws_iam_role.lambda_collect_user_filtered_data_role.name
  policy_arn = var.glue_s3_bucket_read_policy_arn
}

resource "aws_iam_role_policy_attachment" "output_s3_write_policy_attachment" {
  role       = aws_iam_role.lambda_collect_user_filtered_data_role.name
  policy_arn = var.output_bucket_write_policy_arn
}
