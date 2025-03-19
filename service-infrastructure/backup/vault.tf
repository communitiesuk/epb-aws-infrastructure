data "aws_caller_identity" "current" {}

resource "aws_backup_vault" "this" {
  name        = "backup_vault"
  kms_key_arn = var.kms_key_arn
}

data "aws_iam_policy_document" "this" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.backup_account_id}:root"]
    }

    actions = [
      "backup:CopyIntoBackupVault"
    ]

    resources = [aws_backup_vault.this.arn]
  }
}

resource "aws_backup_vault_policy" "this" {
  backup_vault_name = aws_backup_vault.this.name
  policy            = data.aws_iam_policy_document.this.json
}

resource "aws_backup_plan" "this" {
  name = "register_backup_plan"

  rule {
    rule_name         = "register_backup_rule"
    target_vault_name = aws_backup_vault.this.name
    schedule          = var.backup_frequency

    lifecycle {
      delete_after = 14
    }

    copy_action {
      destination_vault_arn = "arn:aws:backup:eu-west-2:${var.backup_account_id}:backup-vault:${var.backup_account_vault_name}"
      lifecycle {
        delete_after = 14
      }
    }
  }
}

resource "aws_backup_selection" "this" {
  iam_role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/service-role/AWSBackupDefaultServiceRole"
  name         = "resource_assignment"
  plan_id      = aws_backup_plan.this.id

  resources = [
    var.database_to_backup_arn
  ]
}