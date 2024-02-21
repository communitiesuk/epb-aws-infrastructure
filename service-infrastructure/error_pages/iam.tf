resource "aws_s3_bucket_policy" "allow_bucket_access" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.allow_bucket_access_doc.json
}

data "aws_iam_policy_document" "allow_bucket_access_doc" {
  statement {
    actions = [
      "s3:GetObject",
    ]

    principals {
      type        = "AWS"
      identifiers = [var.oai_iam_arn]
    }

    effect = "Allow"
    resources = [
      "${aws_s3_bucket.this.arn}/*"
    ]
  }
}