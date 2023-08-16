resource "aws_s3_bucket_policy" "allow_bucket_access" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.allow_bucket_access_doc.json
}

data "aws_iam_policy_document" "allow_bucket_access_doc" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.ci_account_id}:root"]
    }
    effect = "Allow"
    actions = [
      "s3:GetLifecycleConfiguration",
      "s3:ListBucket",
      "s3:DeleteObject",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
      "s3:PutObjectAcl",
    ]

    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*",
    ]
  }
  statement {
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${aws_s3_bucket.this.arn}/*"
    ]

    effect = "Allow"

    condition {
      test     = "StringEquals"
      values   = [aws_cloudfront_distribution.api_docs_s3_distribution.arn]
      variable = "aws:SourceAccount"
    }
  }

  statement {
    actions = [
      "s3:GetObject",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    effect = "Allow"
    resources = [
      "${aws_s3_bucket.this.arn}/*"
    ]
  }
}

resource "aws_iam_role_policy" "ci_s3_policy" {
  name = "ci-s3-policy"
  role = var.ci_role_id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetLifecycleConfiguration",
          "s3:ListBucket",
          "s3:DeleteObject",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:PutObjectAcl",
        ]
        Resource = [aws_s3_bucket.this.arn, "${aws_s3_bucket.this.arn}/*"]
      }
    ]
  })
}
