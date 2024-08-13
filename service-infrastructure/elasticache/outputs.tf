output "redis_uri" {
  value       = "redis://${aws_elasticache_cluster.redis.cache_nodes[0].address}:${var.redis_port}"
  description = "Returns the address of the first node of the cluster"
}
