variable "cdn_certificate_arn" {
  type = string
}

variable "waf_acl_arn" {
  type        = string
  description = "Web ACL ARN for WAF. This should be in the us-east-1 region"
}
