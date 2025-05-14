output "private_key_pem" {
  value = tls_private_key.this.private_key_pem
}

output "public_key_pem" {
  value = tls_private_key.this.public_key_pem
}

output "key_id" {
  value = random_uuid.key_id.id
}