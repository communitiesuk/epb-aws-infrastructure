resource "aws_vpc" "this" {
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "epbr-developer-vpc"
  }
  cidr_block = var.cidr_block

}

locals {
  subnets = cidrsubnets(var.cidr_block, 1, 1)
}

resource "aws_subnet" "public_subnet" {
  count                   = 1
  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.subnets[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "epbr-developer-subnet-${count.index + 1}"
  }

}

resource "aws_route_table" "this" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
}

resource "aws_route_table_association" "public_subnet_asso" {
  subnet_id      = aws_subnet.public_subnet[0].id
  route_table_id = aws_route_table.this.id
}