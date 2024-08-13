resource "aws_cloudfront_distribution" "legacy_domain_redirect" {
  origin {
    domain_name = "fake-origin.invalid"
    origin_id   = "nullDomain"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "match-viewer"
      origin_ssl_protocols   = ["SSLv3", "TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  comment = "legacy domain redirect entrypoint"

  aliases = ["find-energy-certificate.digital.communities.gov.uk", "getting-new-energy-certificate.digital.communities.gov.uk"]

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
  enabled = true
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.cdn_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
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
