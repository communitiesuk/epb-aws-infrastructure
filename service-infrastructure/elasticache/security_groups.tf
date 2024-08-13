resource "aws_security_group" "redis" {
  name   = "${var.prefix}-redis-sg"
  vpc_id = var.vpc_id

  ingress {
    protocol    = "tcp"
    from_port   = var.redis_port
    to_port     = var.redis_port
    cidr_blocks = [var.subnet_cidr]
  }

  egress {
    protocol    = "tcp"
    from_port   = var.redis_port
    to_port     = var.redis_port
    cidr_blocks = [var.subnet_cidr]
  }

  lifecycle {
    create_before_destroy = true
  }
}
