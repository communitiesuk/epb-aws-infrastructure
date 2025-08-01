resource "aws_cloudfront_origin_access_control" "this" {
  name                              = aws_s3_bucket.this.bucket_domain_name
  description                       = "api docs bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "api_docs_s3_distribution" {

  comment         = "EPB OpenAPI documentation CDN"
  enabled         = true
  is_ipv6_enabled = true
  price_class     = "PriceClass_100" # Affects CDN distribution https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/PriceClass.html
  aliases         = [aws_acm_certificate.cert-cdn.domain_name]

  origin {
    domain_name              = aws_s3_bucket.this.bucket_domain_name
    origin_id                = "S3-${var.bucket_name}"
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
  }
  # By default, show index.html file
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${var.bucket_name}"

    forwarded_values {
      query_string = true

      cookies {
        forward = "all"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

  }

  # If there is a 404, return index.html with a HTTP 200 Response
  custom_error_response {
    error_caching_min_ttl = 3000
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
  }


  # Restricts who is able to access this content
  restrictions {
    geo_restriction {
      # type of restriction, blacklist, whitelist or none
      restriction_type = "none"
    }
  }

  # SSL certificate for the service.
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert-cdn.arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }


  ordered_cache_behavior {
    allowed_methods        = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods         = ["GET", "HEAD"]
    path_pattern           = "*"
    target_origin_id       = "S3-${var.bucket_name}"
    viewer_protocol_policy = "allow-all"
    forwarded_values {
      query_string = true
      cookies {
        forward = "all"
      }
    }
  }
}
