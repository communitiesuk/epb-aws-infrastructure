resource "aws_acm_certificate" "this" {
  domain_name       = "*.centraldatastore.net"
  validation_method = "DNS"
}