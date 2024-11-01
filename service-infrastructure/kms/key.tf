data "aws_caller_identity" "current" {}

resource "aws_kms_key" "this" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 7
  multi_region            = false
  enable_key_rotation     = true
  # Must be a number between 90 and 2560 (inclusive).
  rotation_period_in_days = var.environment == "intg" ? 90 : 365

  policy = <<POLICY
  {
    "Version": "2012-10-17",
    "Id": "auto-rds-2",
    "Statement": [
        {
            "Sid": "Enable IAM User Permissions",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        },
        {
            "Sid": "Allow access through RDS for all principals in the account that are authorized to use RDS",
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Action": [
                "kms:Encrypt",
                "kms:Decrypt",
                "kms:ReEncrypt*",
                "kms:GenerateDataKey*",
                "kms:CreateGrant",
                "kms:ListGrants",
                "kms:DescribeKey"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "kms:CallerAccount": "${data.aws_caller_identity.current.account_id}",
                    "kms:ViaService": "rds.eu-west-2.amazonaws.com"
                }
            }
        },
        {
            "Sid": "Allow direct access to key metadata to the account",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
            },
            "Action": [
                "kms:Describe*",
                "kms:Get*",
                "kms:List*",
                "kms:RevokeGrant"
            ],
            "Resource": "*"
        }
    ]
}
POLICY
}


resource "aws_kms_alias" "this" {
  name          = "alias/${var.prefix}-rds-custom-encryption-key"
  target_key_id = aws_kms_key.this.key_id
}

