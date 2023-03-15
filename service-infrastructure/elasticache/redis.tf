resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.prefix}-redis"
  engine               = "redis"
  node_type            = "cache.t3.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis3.2.4"

  apply_immediately          = true
  auto_minor_version_upgrade = true
  engine_version             = "6.x"
  port                       = var.redis_port
  maintenance_window         = "mon:03:00-mon:07:00"
  security_group_ids         = [aws_security_group.redis.id]
  snapshot_retention_limit   = 0
  subnet_group_name          = var.subnet_group_name

  log_delivery_configuration {
    destination      = var.aws_cloudwatch_log_group_name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "slow-log"
  }
}
