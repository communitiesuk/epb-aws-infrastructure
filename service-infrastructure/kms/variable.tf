variable "prefix" {
  description = "Prefix that will be used for naming resources. '<prefix>resouce-name'."
  type        = string
  default     = null
}

variable "environment" {
  type    = string
  default = null
}
