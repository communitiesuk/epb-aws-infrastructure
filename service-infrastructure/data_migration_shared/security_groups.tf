resource "aws_security_group" "postgres_access" {
  name   = "${var.prefix}-ecs-sg"
  vpc_id = var.vpc_id

  egress {
    protocol         = "tcp"
    from_port        = 5432
    to_port          = 5432
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
