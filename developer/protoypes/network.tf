resource "aws_vpc" "this" {
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "epbr-developer-vpc"
  }
  cidr_block = var.cidr_block

}

locals {
  availability_zones = ["a", "b", "c"]
}

resource "aws_subnet" "public_subnet" {
  count                   = length(local.availability_zones)
  vpc_id                  = aws_vpc.this.id
  cidr_block              = cidrsubnet(var.cidr_block, 2, count.index)
  map_public_ip_on_launch = true
  availability_zone       = "${var.region}${local.availability_zones[count.index]}"
  tags = {
    Name = "epbr-developer-public-subnet-${count.index + 1}"
  }

}


