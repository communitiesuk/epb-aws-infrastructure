variable "prefix" {
  type        = string
  description = "project and database name e.g epb-register"
}


variable "schedule_enabled" {
  type    = bool
  default = true
}

variable "rds_reboot_instance" {
  type = object({
    instance_id = string
    schedule    = string
  })

}







