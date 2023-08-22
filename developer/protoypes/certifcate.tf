resource "aws_acm_certificate" "cert" {
  domain_name       = "prototypes.${var.domain_name}"
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_acm_certificate" "cert-cdn" {
  domain_name       = "prototypes.${var.domain_name}"
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  provider = aws.us-east
}

