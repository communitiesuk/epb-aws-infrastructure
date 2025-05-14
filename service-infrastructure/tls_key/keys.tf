resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 2048

  lifecycle {
    prevent_destroy = true
  }
}

resource "random_uuid" "key_id" {
  lifecycle {
    prevent_destroy = true
  }
}