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

variable "front_door_config" {
  type = object({
    aws_ssl_certificate_arn        = string,
    aws_cdn_certificate_arn        = string,
    cdn_allowed_methods            = list(string),
    cdn_cached_methods             = list(string),
    cdn_cache_ttl                  = number,
    cdn_aliases                    = list(string),
    forbidden_ip_addresses_acl_arn = string,
    public_subnet_ids              = list(string),
  })

  default = null
}
