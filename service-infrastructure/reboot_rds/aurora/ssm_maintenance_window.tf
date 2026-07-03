
resource "aws_ssm_maintenance_window" "rds_reboot" {
  for_each = var.schedule_enabled ? var.rds_reboot_aurora_instances : {}

  name        = "${var.prefix}-rds-reboot-${each.key}"
  description = "Scheduled reboot for Aurora DB instance ${each.value.instance_id}"

  schedule          = each.value.schedule
  schedule_timezone = "Europe/London"

  duration = 1
  cutoff   = 0

  allow_unassociated_targets = true
  enabled                    = true

  tags = {
    Name      = "rds-reboot-${each.key}"
    ManagedBy = "terraform"
  }
}

resource "aws_ssm_maintenance_window_task" "rds_reboot" {
  for_each = var.schedule_enabled ? var.rds_reboot_aurora_instances : {}

  window_id = aws_ssm_maintenance_window.rds_reboot[each.key].id

  name        = "${var.prefix}-rds-reboot-${each.key}"
  description = "Reboot RDS DB instance ${each.value.instance_id}"

  task_type = "AUTOMATION"
  task_arn  = "AWS-RebootRdsInstance"

  service_role_arn = aws_iam_role.ssm_maintenance_window.arn

  priority = 1

  task_invocation_parameters {
    automation_parameters {
      document_version = "$DEFAULT"

      parameter {
        name   = "InstanceId"
        values = [each.value.instance_id]
      }

      parameter {
        name   = "AutomationAssumeRole"
        values = [aws_iam_role.ssm_rds_reboot_automation.arn]
      }
    }
  }
}