output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_group_name" {
  value = aws_db_subnet_group.public_subnet_group.name
}

output "private_subnet_group_name" {
  value = aws_db_subnet_group.private_subnet_group.name
}

output "private_subnet_cidr" {
  value = local.private_subnet_cidr
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "private_db_subnet_group_name" {
  value = aws_db_subnet_group.private_db_subnet_group.name
}

output "private_db_subnet_cidr" {
  value = local.private_db_subnet_cidr
}

output "private_db_subnet_ids" {
  value = aws_subnet.private_db[*].id
}

output "private_db_subnet_first_id" {
  value = aws_subnet.private_db[0].id
}

output "private_db_subnet_first_az" {
  value = aws_subnet.private_db[0].availability_zone
}
