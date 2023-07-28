resource "aws_security_group" "rds_security_group" {
  name   = "${var.prefix}-rds-sg"
  vpc_id = var.vpc_id

  ingress {
    security_groups = var.security_group_ids
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
  }

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    description     = "inbound traffic from paas"
    cidr_blocks     = [var.pass_vpc_cidr]
  }

  tags = {
    Name = "${var.prefix}-rds-sg"
  }

  lifecycle {
    create_before_destroy = true
  }

  egress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    description = "outbound traffic to paas"
    cidr_blocks = [var.pass_vpc_cidr]
  }

}

