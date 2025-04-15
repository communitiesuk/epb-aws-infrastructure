variable "prefix" {
  type = string
}

variable "output_file" {
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

variable "lambda_timeout" {
  type    = number
  default = 3
}



