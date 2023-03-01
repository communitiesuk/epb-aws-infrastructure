output "vpc_id" {
  value = aws_vpc.this.id
}

output "public_subnet_group_name" {
  value = aws_db_subnet_group.public_subnet_group.name
}

output "private_subnet_group_name" {
  value = aws_db_subnet_group.private_subnet_group.name
}

output "public_subnet_ids" {
  value = aws_subnet.public.*.id
}

output "private_subnet_ids" {
  value = aws_subnet.private.*.id
}