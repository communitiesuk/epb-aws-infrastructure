data "aws_ssm_parameter" "logstash_port" {
  name = "LOGSTASH_PORT"
}

data "aws_iam_policy" "elasticache_full_access" {
  name = "AmazonElastiCacheFullAccess"
}
