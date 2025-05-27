variable "schedule_expression" {
  type = string
}

variable "schedule_expression_timezone" {
  type    = string
  default = "Europe/London"
}

variable "name" {
  type = string
}

variable "pipeline_arn" {
  type = string
}

variable "iam_role_arn" {
  type = string
}

variable "group_name" {
  type = string
}

