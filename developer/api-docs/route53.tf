# data source to fetch hosted zone info from domain name:
data "aws_route53_zone" "hosted_zone" {
  name = var.domain_name
}


# validate cert:
resource "aws_route53_record" "this" {
  for_each = {
    for d in aws_acm_certificate.cert-cdn.domain_validation_options : d.domain_name => {
      name   = d.resource_record_name
      record = d.resource_record_value
      type   = d.resource_record_type
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.hosted_zone.zone_id
}


# creating A record for domain:
resource "aws_route53_record" "website_url" {
  name    = aws_acm_certificate.cert-cdn.domain_name
  zone_id = data.aws_route53_zone.hosted_zone.id
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.api_docs_s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.api_docs_s3_distribution.hosted_zone_id
    evaluate_target_health = true
  }
}
