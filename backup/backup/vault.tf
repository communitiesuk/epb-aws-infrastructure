resource "aws_backup_vault" "this" {
  name        = "backup_vault"
  kms_key_arn = var.kms_key_arn
}

data "aws_iam_policy_document" "this" {
  statement {
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = ["arn:aws:iam::${var.account_ids["integration"]}:root",
        "arn:aws:iam::${var.account_ids["staging"]}:root",
      "arn:aws:iam::${var.account_ids["production"]}:root"]
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