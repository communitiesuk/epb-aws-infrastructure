resource "aws_vpc" "this" {
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "epbr-developer-vpc"
  }
  cidr_block = var.cidr_block

}

locals {
  subnets = cidrsubnets(var.cidr_block, 1, 1)
}

resource "aws_subnet" "public_subnet" {
  count                   = 1
  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.subnets[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "epbr-developer-subnet-${count.index + 1}"
  }

}

#resource "aws_ecs_na" "this" {
#  subnet_id       = aws_subnet.public_subnet.id
#  private_ips     = ["10.0.0.50"]
#  security_groups = [aws_security_group.ecs.id]
#
#  attachment {
#    instance     = aws_instance.test.id
#    device_index = 1
#  }
#}