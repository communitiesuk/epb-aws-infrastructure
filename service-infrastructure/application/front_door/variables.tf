variable "prefix" {
  type = string
}

variable "container_port" {
  type = number
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "health_check_path" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "logs_bucket_url" {
  type = string
}

variable "logs_bucket_name" {
  type = string
}

variable "ssl_certificate_arn" {
  type = string
}

variable "cdn_certificate_arn" {
  type = string
}


variable "cdn_allowed_methods" {
  type = list(string)

  validation {
    condition     = length(var.cdn_allowed_methods) == 0 || length(var.cdn_allowed_methods) > 0
    error_message = "cdn_cached_methods must be empty"
  }
}

variable "cdn_cached_methods" {
  type = list(string)

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
  type        = set(string)
  description = "the aliases for the CDN. These should be the same as the domain pointing at this CDN from in Route 53"
}

variable "forbidden_ip_addresses_acl_arn" {
  type        = string
  description = "Web ACL ARN for WAF. This should be in the us-east-1 region"
}

variable "path_based_routing_overrides" {
  type = list(object({
    path_pattern     = list(string)
    target_group_arn = string
  }))

  default = []
}

variable "extra_lb_target_groups" {
  type    = number
  default = 0
}

variable "cdn_cache_cookie_behaviour" {
  type    = string
  default = "all"
}

variable "cdn_cache_cookie_items" {
  type    = list(string)
  default = []
}

