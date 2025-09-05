resource "aws_iam_role" "glueServiceRole" {
  name = "AWSGlueServiceRole-${var.prefix}-${var.module_prefix}-glue"
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

resource "aws_iam_role_policy_attachment" "output_bucket_read_policy_attachment" {
  policy_arn = var.output_bucket_read_policy
  role       = aws_iam_role.glueServiceRole.name
}

resource "aws_iam_role_policy_attachment" "output_bucket_write_policy_attachment" {
  policy_arn = var.output_bucket_write_policy
  role       = aws_iam_role.glueServiceRole.name
}

resource "aws_iam_role_policy" "secret_access" {
  name = "${var.prefix}-${var.module_prefix}-glue-role-secret-access-db-creds-policy"
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