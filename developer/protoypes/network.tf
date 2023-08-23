locals {
  availability_zones  = ["a", "b", "c"]
  subnet_ranges       = cidrsubnets(var.cidr_block, 4, 10)
  public_subnet_cidr  = local.subnet_ranges[0]
  private_subnet_cidr = local.subnet_ranges[1]
}


resource "aws_vpc" "this" {
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "epbr-developer-vpc"
  }
  cidr_block = var.cidr_block

}


resource "aws_subnet" "public_subnet" {
  count                   = length(local.availability_zones)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(local.public_subnet_cidr, 2, count.index)
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}${local.availability_zones[count.index]}"
  tags = {
    Name = "epbr-developer-public-subnet-${count.index + 1}"
  }

}

resource "aws_subnet" "private_subnet" {
  count                   = length(local.availability_zones)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(local.private_subnet_cidr, 2, count.index)
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}${local.availability_zones[count.index]}"
  tags = {
    Name = "epbr-developer-private-subnet-${count.index + 1}"
  }

}

