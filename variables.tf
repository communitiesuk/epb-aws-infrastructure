variable "environment" {
  default = "integration"
  type    = string
}

variable "prefix" {
   default = "epb-${var.environment}"
    type    = string
}