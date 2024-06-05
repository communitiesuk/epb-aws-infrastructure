resource "aws_security_group" "dms" {
  name   = "${var.prefix}-${var.name}-security-group"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.tag}-sg"
  }

  lifecycle {
    create_before_destroy = true
  }

}