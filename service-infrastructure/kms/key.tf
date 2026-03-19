data "aws_caller_identity" "current" {}

resource "aws_kms_key" "this" {
  description             = var.description
  deletion_window_in_days = 7
  multi_region            = false
  enable_key_rotation     = true
  # Must be a number between 90 and 2560 (inclusive).
  rotation_period_in_days = var.environment == "intg" ? 90 : 365

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Id" : "auto-${var.policy_id_suffix}",
      "Statement" : concat(
        [
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
            "Sid" : "Allow access through AWS services for all principals in the account that are authorized to use them",
            "Effect" : "Allow",
            "Principal" : {
              "AWS" : "*"
            },
            "Action" : [
              "kms:Encrypt",
              "kms:Decrypt",
              "kms:ReEncrypt*",
              "kms:GenerateDataKey*",
              "kms:CreateGrant",
              "kms:ListGrants",
              "kms:DescribeKey"
            ],
            "Resource" : "*",
            "Condition" : {
              "StringEquals" : merge(
                {
                  "kms:CallerAccount" : distinct(compact([
                    data.aws_caller_identity.current.account_id,
                    var.backup_account_id
                  ]))
                },
                length(var.via_services) > 0 ? { "kms:ViaService" : var.via_services } : {}
              )
            }
          },
          {
            "Sid" : "Allow direct access to key metadata to the account",
            "Effect" : "Allow",
            "Principal" : {
              "AWS" : distinct(compact([
                "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
                var.backup_account_id != null ? "arn:aws:iam::${var.backup_account_id}:root" : null
              ]))
            },
            "Action" : [
              "kms:Describe*",
              "kms:Get*",
              "kms:List*",
              "kms:RevokeGrant"
            ],
            "Resource" : "*"
          }
        ],
        var.enable_sns_kms_key_policy ? [
          {
            "Sid" : "Allow SNS service to use the key",
            "Effect" : "Allow",
            "Principal" : {
              "Service" : "sns.amazonaws.com"
            },
            "Action" : [
              "kms:Decrypt",
              "kms:GenerateDataKey"
            ],
            "Resource" : "*",
            "Condition" : {
              "StringEquals" : {
                "aws:SourceAccount" : local.aws_account_id
              },
              "ArnLike" : {
                "aws:SourceArn" : "arn:aws:sns:${var.region}:${local.aws_account_id}:*"
              }
            }
          }
        ] : []
      )
    }
  )
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.prefix}-${var.alias_suffix}"
  target_key_id = aws_kms_key.this.key_id
}
