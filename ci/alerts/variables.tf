variable "region" {
  type = string
}

variable "environment" {
  type = string
}

variable "main_slack_webhook_url" {
  type      = string
  sensitive = true
}

variable "cloudtrail_log_group_name" {
  type = string
}
