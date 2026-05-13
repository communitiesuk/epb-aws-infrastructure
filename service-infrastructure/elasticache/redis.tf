resource "aws_elasticache_cluster" "redis" {
  cluster_id = "${var.prefix}-redis"

  engine = "redis"
  # If updating the engine_version, ensure the version referenced for the parameter_group_name tallies
  engine_version = "7.1"
  # Parameter group families are outlined here - https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/ParameterGroups.Redis.html
  parameter_group_name       = "default.redis7"
  node_type                  = "cache.t3.micro"
  num_cache_nodes            = 1
  apply_immediately          = true
  auto_minor_version_upgrade = true
  port                       = var.redis_port
  maintenance_window         = "mon:03:00-mon:07:00"
  security_group_ids         = [aws_security_group.redis.id]
  snapshot_retention_limit   = 0
  subnet_group_name          = aws_elasticache_subnet_group.this.name

  log_delivery_configuration {
    destination      = var.aws_cloudwatch_log_group_name
    destination_type = "cloudwatch-logs"
    log_format       = "json"
    log_type         = "slow-log"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_elasticache_subnet_group" "this" {
  name       = "${var.prefix}-redis-subnet"
  subnet_ids = var.subnet_ids
}



resource "aws_elasticache_replication_group" "this" {
  replication_group_id = "${var.prefix}-redis-group"
  description          = "epb redis replication group"
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = "cache.t3.micro"

  replicas_per_node_group    = 2
  automatic_failover_enabled = true
  multi_az_enabled           = true

  parameter_group_name = "default.redis7"
  maintenance_window   = "sun:01:00-sun:03:00"

  snapshot_retention_limit = 1
  snapshot_window          = "03:00-04:00"

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = [aws_security_group.redis.id]

}

