resource "random_password" "cdn_header" {
  length  = 16
  special = false
}

resource "aws_cloudfront_distribution" "cdn" {
  for_each = var.cdn_aliases

  enabled         = true
  is_ipv6_enabled = true
  comment         = "${var.prefix} entrypoint"
  price_class     = "PriceClass_100" # Affects CDN distribution https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PriceClass.html
  aliases         = [each.value]
  web_acl_id      = var.forbidden_ip_addresses_acl_arn

  origin {
    domain_name = aws_lb.public.dns_name
    origin_id   = local.origin_id

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "https-only"
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_read_timeout      = 60
      origin_keepalive_timeout = 60
    }

    custom_header {
      name  = local.cdn_header_name
      value = random_password.cdn_header.result
    }
  }

  default_cache_behavior {
    allowed_methods          = var.cdn_allowed_methods
    cached_methods           = var.cdn_cached_methods
    target_origin_id         = local.origin_id
    viewer_protocol_policy   = "redirect-to-https"
    origin_request_policy_id = aws_cloudfront_origin_request_policy.cdn.id

    cache_policy_id = var.cdn_cache_ttl > 0 ? aws_cloudfront_cache_policy.ttl_based[0].id : data.aws_cloudfront_cache_policy.caching_disabled.id
  }

  ordered_cache_behavior {
    allowed_methods          = ["GET", "HEAD"]
    cached_methods           = ["GET", "HEAD"]
    path_pattern             = var.health_check_path
    target_origin_id         = local.origin_id
    viewer_protocol_policy   = "redirect-to-https"
    origin_request_policy_id = aws_cloudfront_origin_request_policy.cdn.id
    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
  }

  viewer_certificate {
    acm_certificate_arn      = var.cdn_certificate_arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  logging_config {
    include_cookies = false
    bucket          = var.logs_bucket_url
    prefix          = "${var.prefix}-cdn"
  }

  tags = {
    Name    = "CDN Distribution"
    Address = each.value
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_cloudfront_origin_request_policy" "cdn" {
  name    = "${var.prefix}-cdn-origin-request-policy"
  comment = "Origin request policy for the CDN distribution"

  cookies_config {
    cookie_behavior = "all"
  }

  # TODO: Check for any headers we want to restrict
  headers_config {
    header_behavior = "allViewer"
  }

  query_strings_config {
    query_string_behavior = "all"
  }
}

resource "aws_cloudfront_cache_policy" "ttl_based" {
  count = var.cdn_cache_ttl > 0 ? 1 : 0

  name        = "${var.prefix}-ttl-${var.cdn_cache_ttl}"
  min_ttl     = 1
  default_ttl = var.cdn_cache_ttl

  parameters_in_cache_key_and_forwarded_to_origin {
    cookies_config {
      cookie_behavior = "all"
    }

    query_strings_config {
      query_string_behavior = "all"
    }

    headers_config {
      header_behavior = "none"
    }

    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true
  }
}

resource "aws_shield_protection" "cdn" {
  for_each = var.cdn_aliases

  name         = "${var.prefix}-cdn-protection-${each.key}"
  resource_arn = aws_cloudfront_distribution.cdn[each.key].arn
}
