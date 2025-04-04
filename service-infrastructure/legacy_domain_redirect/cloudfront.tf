resource "aws_cloudfront_distribution" "legacy_domain_redirect" {
  comment         = "Legacy (pre-public-beta) domain redirect entrypoint"
  enabled         = true
  is_ipv6_enabled = true
  price_class     = "PriceClass_100" # Affects CDN distribution https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PriceClass.html
  aliases         = ["find-energy-certificate.digital.communities.gov.uk", "getting-new-energy-certificate.digital.communities.gov.uk"]
  web_acl_id      = var.waf_acl_arn

  origin {
    domain_name = "fake-origin.invalid"
    origin_id   = "nullDomain"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "nullDomain"
    viewer_protocol_policy = "redirect-to-https"
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.this.arn
    }
    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.cdn_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

resource "aws_cloudfront_function" "this" {
  name    = "legacy-domain-redirect"
  comment = "redirecting legacy domain to new domain"
  runtime = "cloudfront-js-1.0"
  publish = true
  code = templatefile("${path.module}/function.js",
    { OLD_GET_HOST = "getting-new-energy-certificate.digital.communities.gov.uk",
      NEW_GET_HOST = "getting-new-energy-certificate.service.gov.uk",
  NEW_FIND_HOST = "find-energy-certificate.service.gov.uk" })
}
