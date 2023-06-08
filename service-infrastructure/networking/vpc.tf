locals {
  public_subnet_cidr  = cidrsubnet(var.vpc_cidr_block, 1, 0)
  private_subnet_cidr = cidrsubnet(var.vpc_cidr_block, 1, 1)
}

resource "aws_vpc" "this" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.prefix}-vpc"
  }
}

resource "aws_subnet" "public" {
  count             = length(local.availability_zones)
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(local.public_subnet_cidr, 2, count.index)
  availability_zone = "${var.region}${local.availability_zones[count.index]}"

  map_public_ip_on_launch = true

  tags = {
    Name = "${var.prefix}-public-subnet-${local.availability_zones[count.index]}"
  }
}

resource "aws_subnet" "private" {
  count             = length(local.availability_zones)
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(local.private_subnet_cidr, 2, count.index)
  availability_zone = "${var.region}${local.availability_zones[count.index]}"

  tags = {
    Name = "${var.prefix}-private-subnet-${local.availability_zones[count.index]}"
  }
}

resource "aws_db_subnet_group" "public_subnet_group" {
  name       = "${var.prefix}-public-subnet-group"
  subnet_ids = aws_subnet.public[*].id
}

resource "aws_db_subnet_group" "private_subnet_group" {
  name       = "${var.prefix}-private-subnet-group"
  subnet_ids = aws_subnet.private[*].id
}

resource "aws_network_acl" "public_subnets" {
  vpc_id     = aws_vpc.this.id
  subnet_ids = toset(aws_subnet.public[*].id)

  ingress {
    from_port  = 80
    to_port    = 80
    rule_no    = 100
    action     = "allow"
    protocol   = "tcp"
    cidr_block = "0.0.0.0/0"
  }

  ingress {
    from_port  = 443
    to_port    = 443
    rule_no    = 101
    action     = "allow"
    protocol   = "tcp"
    cidr_block = "0.0.0.0/0"
  }

  ingress {
    from_port  = 0
    to_port    = 0
    rule_no    = 102
    action     = "allow"
    protocol   = -1
    cidr_block = var.vpc_cidr_block
  }

  egress {
    from_port  = 0
    to_port    = 0
    rule_no    = 100
    action     = "allow"
    protocol   = -1
    cidr_block = "0.0.0.0/0"
  }
}

resource "aws_network_acl" "private_subnets" {
  vpc_id     = aws_vpc.this.id
  subnet_ids = toset(aws_subnet.private[*].id)

  ingress {
    from_port  = 0
    to_port    = 0
    rule_no    = 100
    action     = "allow"
    protocol   = -1
    cidr_block = var.vpc_cidr_block
  }

  egress {
    from_port  = 0
    to_port    = 0
    rule_no    = 100
    action     = "allow"
    protocol   = -1
    cidr_block = "0.0.0.0/0"
  }
}
