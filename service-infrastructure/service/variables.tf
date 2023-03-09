variable "prefix" {
  type = string
}

variable "region" {
  type = string
}

variable "container_port" {
  type = number
}

variable "environment_variables" {
  type = list(map(string))
}

variable "secrets" {
  type = map(string)
}

variable "parameters" {
  type = map(string)
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}
variable "health_check_path" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "additional_task_role_policy_arns" {
  type        = map(string)
  default     = {}
  description = "these should not include secrets, parameters or ECS execution specific policies"
}

variable "additional_task_execution_role_policy_arns" {
  type        = map(string)
  default     = {}
  description = "these should not include secrets, parameters or ECS execution specific policies"
}

variable "aws_cloudwatch_log_group_id" {
  type = string
}

variable "logs_bucket_name" {
  type = string
}

variable "logs_bucket_url" {
  type = string
}

variable "create_internal_alb" {
  type    = bool
  default = true
}

variable "aws_ssl_certificate_arn" {
  type = string
}

variable "aws_cdn_certificate_arn" {
  type = string
}


variable "cdn_allowed_methods" {
  type        = list(string)
  description = "all by default, otherwise a list of allowed methods to be used by the CDN"
  default     = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]

  validation {
    condition     = length(var.cdn_allowed_methods) == 0 || length(var.cdn_allowed_methods) > 0
    error_message = "cdn_cached_methods must be empty"
  }
}

variable "cdn_cached_methods" {
  type        = list(string)
  description = "all by default, otherwise a list of methods cached by the CDN"
  default     = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]

  validation {
    condition     = length(var.cdn_cached_methods) == 0 || length(var.cdn_cached_methods) > 0
    error_message = "cdn_cached_methods must be empty"
  }
}

variable "cdn_cache_ttl" {
  type        = number
  description = "default cache TTL for the CDN"
  default     = 0
}

variable "cdn_aliases" {
  type        = list(string)
  description = "the aliases for the CDN. These should be the same as the domain pointing at this CDN from in Route 53"
}
