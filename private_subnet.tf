resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.128.0/17"

  tags = {
    Name = "epbr-${var.environment}-private-subnet"
  }
}
