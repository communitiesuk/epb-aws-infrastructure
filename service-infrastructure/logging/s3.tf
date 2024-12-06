resource "aws_s3_bucket" "logs" {
  bucket = "${var.prefix}-logs"
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "bucket_owner" {
  bucket = aws_s3_bucket.logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "all_logs"
    status = "Enabled"

    expiration {
      days = 14
    }
  }
}

# Used by logit.io
resource "aws_s3_bucket_policy" "root_log_bucket_access" {
  bucket = aws_s3_bucket.logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::652711504416:root"
        }
        Action   = "s3:*"
        Resource = "${aws_s3_bucket.logs.arn}/*",
      },
      {
        Action = "s3:GetBucketAcl"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Resource = [aws_s3_bucket.logs.arn]
        Sid      = "AWSCloudTrailAclCheck"
      },
      {
        Action = "s3:PutObject"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Resource = ["${aws_s3_bucket.logs.arn}/cloudtrail/AWSLogs/*"]
      }
    ]
  })
}

# Used by logit.io
resource "aws_iam_policy" "s3_logs_read_access" {
  name = "${var.prefix}-s3-logs-read-access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Read"
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = [
          "${aws_s3_bucket.logs.arn}/*"
        ]
      },
      {
        Sid    = "List"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.logs.arn
        ]
      }
    ]
  })
}

# Test out Cloud insights

# Create IAM Role with the relevant permission to access S3 and write logs to cloudwatch
resource "aws_iam_role" "lambda_forward_logs_s3_cloudwatch_role" {
  count = var.is_cloudwatch_insights_on
  name  = "${var.prefix}-lambda-forward-logs-s3-cloudwatch-role"

  assume_role_policy = <<EOF
  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Effect": "Allow",
              "Principal": {
                  "Service": "lambda.amazonaws.com"
              },
              "Action": "sts:AssumeRole"
          }
      ]
  }
EOF
}

resource "aws_iam_role_policy" "lambda_forward_logs_s3_cloudwatch_role_policy" {
  count  = var.is_cloudwatch_insights_on
  name   = "${var.prefix}-lambda-forward-logs-s3-cloudwatch-policy"
  role   = aws_iam_role.lambda_forward_logs_s3_cloudwatch_role[0].id
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ],
        "Resource": "*"
      },
      {
        "Action": [
          "s3:GetObject"
        ],
        "Effect": "Allow",
        "Resource": ["*"]
      }
    ]
  }
  EOF
}

# Create the cloudwatch log group.
resource "aws_cloudwatch_log_group" "s3_logs" {
  count             = var.is_cloudwatch_insights_on
  name              = "${var.prefix}-s3-logs"
  retention_in_days = 14
  skip_destroy      = true
}

# -------------------------------------------------------------------------
# lambda function to forward logs from s3 to cloudwatch (ALB and cloudfront)
# --------------------------------------------------------------------------

data "archive_file" "archive_pipe_logs_s3_cloudwatch_lambda" {
  type        = "zip"
  source_file = "${path.module}/functions/forward-logs-cloudwatch-lambda/index.mjs"
  output_path = "${path.module}/functions/forward-logs-cloudwatch-lambda/archive.zip"
}

resource "aws_lambda_function" "forward_logs_s3_cloudwatch" {
  count         = var.is_cloudwatch_insights_on
  filename      = "${path.module}/functions/forward-logs-cloudwatch-lambda/archive.zip"
  function_name = "${var.prefix}-forward-logs"
  role          = aws_iam_role.lambda_forward_logs_s3_cloudwatch_role[0].arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = 30

  // Redeploy when lambda function code change
  source_code_hash = data.archive_file.archive_pipe_logs_s3_cloudwatch_lambda.output_base64sha256

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      environment  = var.prefix
      logGroupName = aws_cloudwatch_log_group.s3_logs[0].name
    }
  }
}

resource "aws_lambda_permission" "allow_bucket_forward_logs" {
  count         = var.is_cloudwatch_insights_on
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = var.is_cloudwatch_insights_on == 1 ? aws_lambda_function.forward_logs_s3_cloudwatch[0].arn : 0
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.logs.arn
}

resource "aws_s3_bucket_notification" "bucket_log_notification" {
  count  = var.is_cloudwatch_insights_on
  bucket = aws_s3_bucket.logs.id
  lambda_function {
    lambda_function_arn = var.is_cloudwatch_insights_on == 1 ? aws_lambda_function.forward_logs_s3_cloudwatch[0].arn : 0
    events              = ["s3:ObjectCreated:*"] // When new object created in S3 it will trigger the lambda function
  }
  depends_on = [aws_lambda_permission.allow_bucket_forward_logs]
}
