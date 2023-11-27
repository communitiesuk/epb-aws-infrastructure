resource "aws_iam_role" "this" {
  name        = "${var.bucket_name}-role"
  description = "A role Aurora can assume on behalf of the S3 backup bucket"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "export.rds.amazonaws.com"
        }
      }
    ]
  })
}

