locals {
  subnet_ranges          = cidrsubnets(var.vpc_cidr_block, 2, 6, 2)
  private_subnet_cidr    = local.subnet_ranges[0]
  private_db_subnet_cidr = local.subnet_ranges[1]
  public_subnet_cidr     = local.subnet_ranges[2]
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
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

#
resource "aws_subnet" "private_db" {
  count             = length(local.availability_zones)
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(local.private_db_subnet_cidr, 2, count.index)
  availability_zone = "${var.region}${local.availability_zones[count.index]}"

  tags = {
    Name = "${var.prefix}-private-db-subnet-${local.availability_zones[count.index]}"
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

resource "aws_db_subnet_group" "private_db_subnet_group" {
  name       = "${var.prefix}-private-db-subnet-group"
  subnet_ids = aws_subnet.private_db[*].id
}
