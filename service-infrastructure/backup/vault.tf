resource "aws_backup_vault" "this" {
  name        = "${var.prefix}-backup-vault"
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
  name = "${var.prefix}-register-backup-plan"

  rule {
    rule_name         = "${var.prefix}-register-backup-rule"
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
  iam_role_arn = aws_iam_role.this.arn
  name         = "resource_assignment"
  plan_id      = aws_backup_plan.this.id

  resources = [
    var.database_to_backup_arn
  ]
}

resource "aws_iam_role" "this" {
  name               = "${var.prefix}-aws-backup-service-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "attach-backup-policy" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "attach-restore-policy" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}