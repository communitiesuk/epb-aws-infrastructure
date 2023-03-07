resource "aws_acm_certificate" "this" {
  # TODO for production we will need to add logic so that we can provide a different domain name
  domain_name       = "*.centraldatastore.net"
  validation_method = "DNS"
}