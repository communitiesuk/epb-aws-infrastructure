data "aws_caller_identity" "current" {}

resource "aws_kms_key" "this" {
  description             = "KMS key for vault"
  deletion_window_in_days = 7
  multi_region            = false
  enable_key_rotation     = true
  # Must be a number between 90 and 2560 (inclusive).
  rotation_period_in_days = 365

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Id" : "key-for-backup-vault",
      "Statement" : [
        {
          "Sid" : "Enable IAM User Permissions",
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
          },
          "Action" : "kms:*",
          "Resource" : "*"
        },
        {
          "Sid" : "KmsPermissions",
          "Effect" : "Allow",
          "Principal" : {
            "AWS" : "*"
          },
          "Action" : [
            "kms:ListKeys",
            "kms:DescribeKey",
            "kms:GenerateDataKey",
            "kms:ListAliases",
            "kms:CreateGrant"
          ],
          "Resource" : "*",
          "Condition" : {
            "StringEquals" : {
              "kms:CallerAccount" : [
                data.aws_caller_identity.current.account_id,
                var.account_ids["integration"],
                var.account_ids["staging"],
                var.account_ids["production"]
              ],
              "kms:ViaService" : [
                "rds.eu-west-2.amazonaws.com",
                "backup.eu-west-2.amazonaws.com"
              ]
            }
          }
        }
      ]
    }
  )
}


resource "aws_kms_alias" "this" {
  name          = "alias/backup-vault-encryption-key"
  target_key_id = aws_kms_key.this.key_id
}

