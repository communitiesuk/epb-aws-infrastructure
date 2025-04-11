variable "prefix" {
  type = string
}

variable "output_path" {
  type = string
}

variable "function_name" {
  type = string
}

variable "sqs_arn" {
  type = string
}

variable "environment" {
  type    = map(string)
  default = {}
}



