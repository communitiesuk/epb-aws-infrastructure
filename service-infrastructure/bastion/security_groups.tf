resource "aws_security_group" "bastion" {
  name   = "${var.name}-security-group"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.tag}-sg"
  }

  lifecycle {
    create_before_destroy = true
  }

  dynamic "ingress" {
    for_each = var.pass_vpc_cidr
    content {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "inbound traffic from paas"
      cidr_blocks = var.pass_vpc_cidr
    }
  }

  dynamic "egress" {
    for_each = var.pass_vpc_cidr
    content {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "outbound traffic to paas"
      cidr_blocks = var.pass_vpc_cidr
    }
  }

}