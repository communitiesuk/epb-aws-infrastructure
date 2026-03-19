variable "prefix" {
  type = string
}

variable "name" {
  type    = string
  default = "data-frontend"
}

variable "sns_success_feedback_sample_rate" {
  type        = number
  description = "Percentage of successful deliveries to sample for CloudWatch logging."
  default     = 10
}

variable "kms_key_arn" {
  type = string
}