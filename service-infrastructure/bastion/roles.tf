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
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "bastion_role_policy_attachment" {
  role       = aws_iam_role.ec2_rds_access.name
  policy_arn = var.iam_policy_rds_arn
}

resource "aws_iam_instance_profile" "bastion" {
  name = "bastion_profile"
  role = aws_iam_role.ec2_rds_access.name
}
