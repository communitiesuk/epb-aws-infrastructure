resource "aws_iam_role" "ssm_rds_reboot_automation" {
  name = "${var.prefix}-ssm-rds-reboot-automation"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ssm.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "ssm_rds_reboot_automation" {
  name = "${var.prefix}-ssm-rds-reboot-automation"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowRdsReboot"
        Effect = "Allow"
        Action = [
          "rds:RebootDBInstance",
          "rds:DescribeDBInstances",

        ]
        Resource = local.rds_reboot_instance_arns
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_rds_reboot_automation" {
  role       = aws_iam_role.ssm_rds_reboot_automation.name
  policy_arn = aws_iam_policy.ssm_rds_reboot_automation.arn
}

resource "aws_iam_role" "ssm_maintenance_window" {
  name = "${var.prefix}-ssm-rds-reboot-maintenance-window"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ssm.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "ssm_maintenance_window" {
  name = "${var.prefix}-ssm-rds-reboot-maintenance-window"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowStartAutomation"
        Effect = "Allow"
        Action = [
          "ssm:StartAutomationExecution",
          "ssm:GetAutomationExecution"
        ]
        Resource = "*"
      },
      {
        Sid      = "AllowPassAutomationRole"
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = aws_iam_role.ssm_rds_reboot_automation.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_maintenance_window" {
  role       = aws_iam_role.ssm_maintenance_window.name
  policy_arn = aws_iam_policy.ssm_maintenance_window.arn
}