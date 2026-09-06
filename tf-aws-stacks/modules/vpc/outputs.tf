output "vpc_id" {
  value = aws_vpc.this.id
}

output "app_subnet_ids" {
  value = aws_subnet.app[*].id
}

output "db_subnet_ids" {
  value = aws_subnet.db[*].id
}

output "route_table_id" {
  value = aws_route_table.internal.id
}
