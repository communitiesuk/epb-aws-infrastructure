variable "prefix" {
  type = string
}

variable "cluster_arn" {
  type = string
}

variable "private_db_subnet_ids" {
  type = list(string)
}

variable "security_group_id" {
  type = string
}

variable "event_rule_arn" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "app_containers" {
  type = object({
    register_container_name     = string
    register_task_arn           = string
    address_base_container_name = string
    address_base_task_arn       = string
  })
}


