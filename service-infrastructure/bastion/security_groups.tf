resource "aws_security_group" "bastion" {
  name   = "${var.name}-security-group"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.tag}-sg"
  }

  lifecycle {
    create_before_destroy = true
  }

#  ingress {
#    from_port       = 5432
#    to_port         = 5432
#    protocol        = "tcp"
#    description     = "inbound traffic from paas"
#    cidr_blocks     = [var.vpc_cidr_block]
#  }
#
#  egress {
#    from_port       = 5432
#    to_port         = 5432
#    protocol        = "tcp"
#    description = "outbound traffic to paas"
#    cidr_blocks = [var.pass_vpc_cidr]
#  }
}

#resource "aws_security_group_rule" "bastion_paas_inbound_rule" {
#  count = var.pass_vpc_cidr ==""? 0 : 1
#  from_port         = 5432
#  protocol          = "tcp"
#  security_group_id = aws_security_group.bastion.id
#  to_port           = 5432
#  type              = "ingress"
#  cidr_blocks = [var.pass_vpc_cidr]
#  description =  "inbound traffic from paas"
#  lifecycle {create_before_destroy = true}
#}
#
#resource "aws_security_group_rule" "bastion_paas_outbound_rule" {
#  count = var.pass_vpc_cidr ==""? 0 : 1
#  from_port         = 5432
#  protocol          = "tcp"
#  security_group_id = aws_security_group.bastion.id
#  to_port           = 5432
#  type              = "ingress"
#  cidr_blocks = [var.pass_vpc_cidr]
#  description =  "egress traffic to paas"
#
#  lifecycle {create_before_destroy = true}
#}