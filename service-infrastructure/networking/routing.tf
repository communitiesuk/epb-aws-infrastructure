resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = element(aws_subnet.public[*].id, count.index)
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count  = length(aws_subnet.private)
  vpc_id = aws_vpc.this.id
}


resource "aws_route" "private" {
  count                  = length(aws_subnet.private)
  route_table_id         = element(aws_route_table.private[*].id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.this[*].id, count.index)
}


resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = element(aws_subnet.private[*].id, count.index)
  route_table_id = element(aws_route_table.private[*].id, count.index)
}


resource "aws_route_table" "private_db" {
  count  = length(aws_subnet.private_db)
  vpc_id = aws_vpc.this.id
}


resource "aws_route" "private_db" {
  count                  = length(aws_subnet.private_db)
  route_table_id         = element(aws_route_table.private_db[*].id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.this[*].id, count.index)
}

resource "aws_route_table_association" "private_db" {
  count          = length(aws_subnet.private_db)
  subnet_id      = element(aws_subnet.private_db[*].id, count.index)
  route_table_id = element(aws_route_table.private_db[*].id, count.index)
}


resource "aws_route" "private_db_paas_peering" {
  count                     = var.vpc_peering_connection_id == "" ? 0 : length(aws_subnet.private_db)
  route_table_id            = element(aws_route_table.private_db[*].id, count.index)
  destination_cidr_block    = var.pass_vpc_cidr
  vpc_peering_connection_id = var.vpc_peering_connection_id
}

