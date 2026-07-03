variable "prefix" {
  type        = string
  description = "project and database name e.g epb-register"
}


variable "schedule_enabled" {
  type    = bool
  default = true
}

variable "rds_reboot_aurora_instances" {
  description = "DB instances to reboot, keyed by name."
  type = map(object({
    instance_id = string
    schedule    = string
  }))

  default = {
    reader = {
      instance_id = ""
      schedule    = "cron(0 2 ? * SUN *)"
    }

    writer = {
      instance_id = "epb-stag-reg-api-aurora-db-v2-writer"
      schedule    = "cron(30 2 ? * SUN *)"
    }
  }
}





