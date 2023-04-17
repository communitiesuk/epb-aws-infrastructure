variable "environment" {
  description = "must be one of: integration, staging, production"
  type        = string
  validation {
    condition     = contains(["integration", "staging", "production"], var.environment)
    error_message = "Environment must be one of: integration, staging, production"
  }
}
