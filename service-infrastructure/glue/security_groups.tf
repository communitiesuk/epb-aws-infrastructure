locals {
  sg_name = "${var.prefix}-glue-sg"
}

resource "aws_security_group" "glue_security_group" {
  name   = local.sg_name
  vpc_id = var.vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    ipv6_cidr_blocks = []
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = local.sg_name
  }

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_security_group_rule" "ingress_self" {
  type              = "ingress"
  security_group_id = aws_security_group.glue_security_group.id
  from_port         = 0
  protocol          = "tcp"
  to_port           = 65535
  self              = true
}


