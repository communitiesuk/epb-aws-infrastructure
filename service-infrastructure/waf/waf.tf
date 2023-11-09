resource "aws_wafv2_web_acl" "this" {
  name        = "${var.prefix}-waf"
  description = "Web ACL to restrict traffic to CloudFront"

  scope = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "waf-block-bad-input-metrics"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "allow-ip-rule"
    priority = 9

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.allowed_ip_addresses.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "waf-allow-ip-rule-metrics"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "allow-ipv6-rule"
    priority = 10

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.allowed_ipv6_addresses.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "waf-allow-ipv6-rule-metrics"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "block-ip-rule"
    priority = 11

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
    name     = "block-ipv6-rule"
    priority = 12

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.forbidden_ipv6_addresses.arn
      }
    }

    action {
      block {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "waf-block-ipv6-rule-metrics"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "throttle-requests-rule"
    priority = 13

    statement {
      rate_based_statement {
        aggregate_key_type = "IP"
        limit              = var.environment == "stag" ? 1000000 : 1000
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

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_wafv2_ip_set" "allowed_ip_addresses" {
  name               = "${var.prefix}-waf-allowed-ip-addresses"
  description        = "IP Set allowed unthrottled access to the website and other services."
  ip_address_version = "IPV4"
  scope              = "CLOUDFRONT"
  addresses          = var.allowed_ip_addresses
}

resource "aws_wafv2_ip_set" "allowed_ipv6_addresses" {
  name        = "${var.prefix}-waf-allowed-ipv6-addresses"
  description = "IPV6 Set allowed unthrottled access to the website and other services"

  ip_address_version = "IPV6"
  scope              = "CLOUDFRONT"
  addresses          = var.allowed_ipv6_addresses
}

resource "aws_wafv2_ip_set" "forbidden_ip_addresses" {
  name               = "${var.prefix}-waf-forbidden-ip-addresses"
  description        = "IP Set forbidden access to the website and other services."
  ip_address_version = "IPV4"
  scope              = "CLOUDFRONT"
  addresses          = var.forbidden_ip_addresses
}

resource "aws_wafv2_ip_set" "forbidden_ipv6_addresses" {
  name        = "${var.prefix}-waf-forbidden-ipv6-addresses"
  description = "IPV6 Set forbidden access to the website and other services"

  ip_address_version = "IPV6"
  scope              = "CLOUDFRONT"
  addresses          = var.forbidden_ipv6_addresses
}
