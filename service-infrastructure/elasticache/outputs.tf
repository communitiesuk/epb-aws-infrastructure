output "redis_uri" {
  value = "redis://${aws_elasticache_cluster.redis.cluster_address}:${var.redis_port}"
}
