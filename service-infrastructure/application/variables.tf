variable "prefix" {
  type = string
}

variable "region" {
  type = string
}

variable "container_port" {
  type = number
}

variable "egress_ports" {
  type = list(number)
}

variable "environment_variables" {
  type = map(string)
}

variable "ci_account_id" {
  type = string
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

variable "fluentbit_ecr_url" {
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

variable "aws_cloudwatch_log_group_name" {
  type = string
}

variable "logs_bucket_name" {
  type = string
}

variable "logs_bucket_url" {
  type = string
}

variable "internal_alb_config" {
  type = object({
    ssl_certificate_arn = string
  })

  default = null
}

variable "front_door_config" {
  type = object({
    ssl_certificate_arn            = string
    cdn_certificate_arn            = string
    cdn_allowed_methods            = list(string)
    cdn_cached_methods             = list(string)
    cdn_cache_ttl                  = number
    cdn_aliases                    = set(string)
    cdn_cache_cookie_behaviour     = optional(string)
    cdn_cache_cookie_items         = optional(list(string))
    cdn_include_static_error_pages = optional(bool)
    error_pages_bucket_name        = optional(string)
    waf_acl_arn                    = string
    public_subnet_ids              = list(string)
    path_based_routing_overrides = list(object({
      path_pattern     = list(string)
      target_group_arn = string
    }))
    # we can generate n extra load balancer target groups if we need them for e.g. targeting path-based forwarding rules from other load balancers
    extra_lb_target_groups = number
  })

  default = null
}

variable "enable_execute_command" {
  type    = bool
  default = false
}

variable "has_start_task" {
  type    = bool
  default = true
}

variable "has_exec_cmd_task" {
  type    = bool
  default = false
}

variable "has_target_tracking" {
  type    = bool
  default = true
}

variable "task_desired_capacity" {
  type    = number
  default = 2
}

variable "task_min_capacity" {
  type    = number
  default = 2
}

variable "task_max_capacity" {
  type    = number
  default = 4
}

variable "task_cpu" {
  default = 512
  type    = number
}

variable "task_memory" {
  default = 2048
  type    = number
}

variable "fargate_weighting" {
  type    = object({ standard : number, spot : number })
  default = { standard : 10, spot : 0 }
}

variable "external_ecr" {
  type    = string
  default = ""
}

variable "address_base_updater_ecr" {
  type    = string
  default = null
}

variable "exec_cmd_task_cpu" {
  type    = number
  default = 512
}

variable "exec_cmd_task_ram" {
  type    = number
  default = 2048
}

variable "cloudwatch_ecs_events_arn" {
  type = string
}

variable "deployment_minimum_healthy_percent" {
  type    = number
  default = 100
}

variable "is_fluentbit_container_essential" {
  type    = bool
  default = false
}
