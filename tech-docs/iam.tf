
resource "aws_s3_bucket_policy" "allow_access_from_dev_account" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.this.json
}


data "aws_iam_policy_document" "this" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.ci_account_id}:root"]
    }

    actions = [
      "s3:GetLifecycleConfiguration",
      "s3:ListBucket",
      "s3:DeleteObject",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
    ]

    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*",
    ]
  }
}

