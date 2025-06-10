variable "prefix" {
  type = string
}

variable "lifecycle_prefix" {
  type        = string
  default     = null
}

variable "expiration_days" {
  type = number
  default = 30
}
