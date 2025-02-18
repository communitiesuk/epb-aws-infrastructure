resource "aws_iam_role" "glueServiceRole" {
  name = "AWSGlueServiceRole-${var.prefix}-glue"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "glue.amazonaws.com"
      }
    }]
  })
}


resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.glueServiceRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy" "s3_bucket_policy" {
  name = "${var.prefix}-glue-role-s3-policy"
  role = aws_iam_role.glueServiceRole.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject*",
          "s3:ListBucket",
          "s3:GetObject*",
          "s3:DeleteObject*",
          "s3:GetBucketLocation"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.this.arn,
          "${aws_s3_bucket.this.arn}/*"
        ]
      }
    ]
  })

}

resource "aws_iam_role_policy" "secret_access" {
  name = "${var.prefix}-glue-role-secret-access-db-creds-policy"
  role = aws_iam_role.glueServiceRole.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Effect   = "Allow"
        Resource = aws_secretsmanager_secret.glue_db_creds.id
      }
    ]
  })
}
