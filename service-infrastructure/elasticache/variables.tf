variable "aws_cloudwatch_log_group_name" {
  type = string
}

variable "prefix" {
  type = string
}

variable "redis_port" {
  type = number
}

variable "subnet_ids" {
  type = list(string)
}

variable "subnet_cidr" {
  type = string
}

variable "vpc_id" {
  type = string
}
