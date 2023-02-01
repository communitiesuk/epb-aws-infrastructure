locals {
  vpc_cidr = "10.0.0.0/16"
  public_subnet_cidr = cidrsubnet(local.vpc_cidr, 2, 0)
  private_subnet_cidr = cidrsubnet(local.vpc_cidr, 2, 1)
}


resource "aws_vpc" "this" {
  cidr_block = local.vpc_cidr
  tags = {
    Name = "${var.prefix}-vpc"
  }
}

resource "aws_security_group" "internet_access" {
  name        = "${var.prefix}-internet-access"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.this.id

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
    Name = "${var.prefix}-internet-access"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.prefix}-internet-gateway"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.this.id
  cidr_block = local.public_subnet_cidr

  map_public_ip_on_launch = true

  tags = {
    Name = "${var.prefix}-public-subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.this.id
  cidr_block = local.private_subnet_cidr

  tags = {
    Name = "${var.prefix}-private-subnet"
  }
}

