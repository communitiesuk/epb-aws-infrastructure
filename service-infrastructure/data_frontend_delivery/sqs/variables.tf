variable "prefix" {
  type = string
}

variable "name" {
  type    = string
  default = "data-frontend"
}

variable "queue_name" {
  type = string
}

variable "lambda_role_id" {
  type = string
}

variable "lambda_timeout" {
  type = number
}

variable "kms_key_arn" {
  type = string
}
