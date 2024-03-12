variable "prefix" {
  type = string
}

variable "cluster_arn" {
  type = string
}

variable "task_arn" {
  type = string
}

variable "vpc_subnet_ids" {
  type = list(string)
}

variable "security_group_id" {
  type = string
}

variable "container_name" {
  type = string
}


