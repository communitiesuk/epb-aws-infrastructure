resource "aws_vpc" "this" {
  cidr_block = local.vpc_cidr
  tags = {
    Name = "${var.prefix}-vpc"
  }
}

resource "aws_subnet" "public" {
  count             = length(local.availability_zones)
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(local.vpc_cidr, 3, 0 + count.index)
  availability_zone = "${var.region}${local.availability_zones[count.index]}"

  map_public_ip_on_launch = true

  tags = {
    Name = "${var.prefix}-public-subnet-${local.availability_zones[count.index]}"
  }
}

resource "aws_subnet" "private" {
  count             = length(local.availability_zones)
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(local.vpc_cidr, 3, 4 + count.index)
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