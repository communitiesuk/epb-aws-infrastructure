variable "prefix" {
  type = string
}

variable "environment" {
  type = string
}

variable "cloudwatch_log_group_id" {
  type = string
}

variable "cloudwatch_log_group_name" {
  type = string
}

variable "ecs_services" {
  type = map(object({
    cluster_name = string
    service_name = string
  }))
}

variable "rds_instances" {
  type = map(string)
}

variable "rds_clusters" {
  type = map(string)
}
