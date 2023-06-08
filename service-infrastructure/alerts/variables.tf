variable "prefix" {
  type = string
}

variable "region" {
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

variable "albs" {
  type = map(string)
}

variable "slack_webhook_url" {
  type = string
}

variable "logs_bucket_name" {
  type = string
}
