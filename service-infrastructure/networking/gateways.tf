resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.prefix}-internet-gateway"
  }
}

resource "aws_nat_gateway" "this" {
  count         = length(aws_subnet.private)
  allocation_id = element(aws_eip.nat[*].id, count.index)
  subnet_id     = element(aws_subnet.public[*].id, count.index)
  tags = {
    Name = "${var.prefix}-nat-gateway-${count.index}"
  }

  depends_on = [aws_internet_gateway.this]
}

resource "aws_eip" "nat" {
  count = length(aws_subnet.private)
  vpc   = true
}