variable "prefix" {
  type = string
}

variable "region" {
  type = string
}

variable "is_cloudwatch_insights_on" {
  type = number
}

variable "memory_size" {
  type    = number
  default = 128
}
