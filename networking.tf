locals {
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["a", "b"]
}


resource "aws_vpc" "this" {
  cidr_block = local.vpc_cidr
  tags = {
    Name = "${local.prefix}-vpc"
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${local.prefix}-internet-gateway"
  }
}

resource "aws_subnet" "public" {
  count             = length(local.availability_zones)
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(local.vpc_cidr, 3, 0 + count.index)
  availability_zone = "${var.region}${local.availability_zones[count.index]}"

  map_public_ip_on_launch = true

  tags = {
    Name = "${local.prefix}-public-subnet-${local.availability_zones[count.index]}"
  }
}

resource "aws_subnet" "private" {
  count             = length(local.availability_zones)
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(local.vpc_cidr, 3, 4 + count.index)
  availability_zone = "${var.region}${local.availability_zones[count.index]}"

  tags = {
    Name = "${local.prefix}-private-subnet-${local.availability_zones[count.index]}"
  }
}

