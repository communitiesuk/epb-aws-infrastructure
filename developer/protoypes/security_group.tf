resource "aws_security_group" "ecs" {
  name   = "${var.prefix}-ecs-sg"
  vpc_id = aws_vpc.this.id
  ingress {
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}