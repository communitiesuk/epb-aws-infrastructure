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

resource "aws_iam_instance_profile" "bastion" {
  name = "bastion_profile"
  role = aws_iam_role.ec2_rds_access.name
}
