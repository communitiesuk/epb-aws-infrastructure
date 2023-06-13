module "front_door" {
  source = "./front_door"
  count  = var.front_door_config != null ? 1 : 0

  prefix            = var.prefix
  container_port    = var.container_port
  health_check_path = var.health_check_path
  vpc_id            = var.vpc_id
  logs_bucket_name  = var.logs_bucket_name
  logs_bucket_url   = var.logs_bucket_url

  ssl_certificate_arn            = var.front_door_config.ssl_certificate_arn
  cdn_certificate_arn            = var.front_door_config.cdn_certificate_arn
  cdn_allowed_methods            = var.front_door_config.cdn_allowed_methods
  cdn_cached_methods             = var.front_door_config.cdn_cached_methods
  cdn_cache_ttl                  = var.front_door_config.cdn_cache_ttl
  cdn_aliases                    = var.front_door_config.cdn_aliases
  forbidden_ip_addresses_acl_arn = var.front_door_config.forbidden_ip_addresses_acl_arn
  public_subnet_ids              = var.front_door_config.public_subnet_ids
}
