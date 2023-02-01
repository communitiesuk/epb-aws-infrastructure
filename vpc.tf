resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "epbr-${var.environment}-vpc"
  }
}

resource "aws_security_group" "internet_access" {
  name        = "internet-access-${var.environment}"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    #    Terraform docs say the cidr_blocks are optional, however you can't see the rules being applied in the console without them
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    #    Terraform docs say the cidr_blocks are optional, however you can't see the rules being applied in the console without them
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "internet-access-${var.environment}"
  }
}
