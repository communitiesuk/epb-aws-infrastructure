locals {
  sg_name = var.name_suffix == null ? "${var.prefix}-rds-sg" : "${var.prefix}-rds-sg-V2"
}

resource "aws_security_group" "rds_security_group" {
  name   = local.sg_name
  vpc_id = var.vpc_id

  ingress {
    security_groups = var.security_group_ids
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
  }

  lifecycle {
    create_before_destroy = true
  }

}
