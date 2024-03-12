variable "prefix" {
  type = string
}

variable "rule_name" {
  type = string
}

variable "schedule_expression" {
  type = string
}

variable "command" {
  type = list(string)
}

variable "environment" {
  type    = list(map(string))
  default = []
}


variable "task_config" {
  type = object({
    cluster_arn       = string
    security_group_id = string
    vpc_subnet_ids    = list(string)
    task_arn          = string
    event_role_arn    = string
    container_name    = string
  })
}
