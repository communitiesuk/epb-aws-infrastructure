resource "aws_iam_role" "ec2_rds_access" {
  name        = "EC2-RDS-Access"
  description = "Allows EC2 access to RDS on your behalf."

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bastion_role_policy_attachment" {
  for_each = var.rds_access_policy_arns

  role       = aws_iam_role.ec2_rds_access.name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "manage_session" {
  name = "session_policy"
  role = aws_iam_role.ec2_rds_access.name
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
          "ssm:UpdateInstanceInformation"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetEncryptionConfiguration"
        ]
        Resource = "*"
      }
    ]
  })

}

resource "aws_iam_instance_profile" "bastion" {
  name = "bastion_profile"
  role = aws_iam_role.ec2_rds_access.name
}
