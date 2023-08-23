resource "aws_route_table" "this" {
  vpc_id = aws_vpc.this.id
}

resource "aws_route" "public" {
  route_table_id         = aws_route_table.this.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}


resource "aws_route_table_association" "public_subnet_asso" {
  count          = length(aws_subnet.public_subnet)
  subnet_id      = element(aws_subnet.public_subnet[*].id, count.index)
  route_table_id = element(aws_route_table.this[*].id, count.index)
}

#resource "aws_route" "this" {
#  count                  = length(aws_subnet.public_subnet)
#  route_table_id         = element(aws_route_table.this[*].id, count.index)
#  destination_cidr_block = "0.0.0.0/0"
#  nat_gateway_id         = element(aws_nat_gateway.this[*].id, count.index)
#}

resource "aws_route_table" "private" {
  count  = length(aws_subnet.public_subnet)
  vpc_id = aws_vpc.this.id
}


resource "aws_route" "private" {
  count                  = length(aws_subnet.private_subnet)
  route_table_id         = element(aws_route_table.private[*].id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.this[*].id, count.index)
}


resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private_subnet)
  subnet_id      = element(aws_subnet.private_subnet[*].id, count.index)
  route_table_id = element(aws_route_table.private[*].id, count.index)
}
