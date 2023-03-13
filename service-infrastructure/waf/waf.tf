resource "aws_wafv2_web_acl" "this" {
  name        = "${var.prefix}-waf"
  description = "Web ACL to restrict traffic to CloudFront"

  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "block-ip-rule"
    priority = 1

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.forbidden_ip_addresses.arn
      }
    }

    action {
      block {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "waf-block-ip-rule-metrics"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "throttle-requests-rule"
    priority = 2

    statement {
      rate_based_statement {
        aggregate_key_type = "IP"
        limit              = 1000
        scope_down_statement {
          not_statement {
            statement {
              ip_set_reference_statement {
                arn = aws_wafv2_ip_set.forbidden_ip_addresses.arn
              }
            }
          }
        }
      }
    }

    action {
      block {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "throttle-requests-rule"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "waf-metrics"
    sampled_requests_enabled   = false
  }
}

resource "aws_wafv2_ip_set" "forbidden_ip_addresses" {
  name        = "${var.prefix}-waf-forbidden-ip-addresses"
  description = "IP Set forbidden access to the website and other services"

  ip_address_version = "IPV4"
  scope              = "CLOUDFRONT"
  addresses          = var.forbidden_ip_addresses

  lifecycle {
    ignore_changes = [addresses]
  }
}
