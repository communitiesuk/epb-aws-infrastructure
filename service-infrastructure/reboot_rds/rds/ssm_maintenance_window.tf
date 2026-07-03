resource "aws_ssm_maintenance_window" "maintenance_window" {
  count = (var.schedule_enabled == true && var.rds_reboot_instance != null) ? 1 : 0

  name        = "${var.prefix}-rds-reboot"
  description = "Scheduled reboot for RDS DB ${var.rds_reboot_instance.instance_id}"

  schedule          = var.rds_reboot_instance.schedule
  schedule_timezone = "Europe/London"

  duration = 1
  cutoff   = 0

  allow_unassociated_targets = true
  enabled                    = true

  tags = {
    Name      = "${var.prefix}-rds-reboot"
    ManagedBy = "terraform"
  }
}

resource "aws_ssm_maintenance_window_task" "rds_reboot" {

  window_id = aws_ssm_maintenance_window.maintenance_window[0].id

  name        = "${var.prefix}-rds-reboot"
  description = "Reboot RDS DB instance ${var.rds_reboot_instance.instance_id}"

  task_type = "AUTOMATION"
  task_arn  = "AWS-RebootRdsInstance"

  service_role_arn = aws_iam_role.ssm_maintenance_window.arn

  priority = 1

  task_invocation_parameters {
    automation_parameters {
      document_version = "$DEFAULT"

      parameter {
        name   = "InstanceId"
        values = [var.rds_reboot_instance.instance_id]
      }

      parameter {
        name   = "AutomationAssumeRole"
        values = [aws_iam_role.ssm_rds_reboot_automation.arn]
      }
    }
  }
}