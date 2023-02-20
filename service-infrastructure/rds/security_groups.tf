resource "aws_security_group" "rds_security_group" {
  name   = "${var.prefix}-rds-security-group"
  vpc_id = var.vpc_id

  ingress {
    security_groups = var.security_group_ids
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
  }
}
