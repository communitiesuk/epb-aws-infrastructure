resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.this.id
  cidr_block = "10.0.0.0/17"

  map_public_ip_on_launch = true

  tags = {
    Name = "epbr-${var.environment}-public-subnet"
  }
}
