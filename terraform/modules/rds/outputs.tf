
output "database_endpoint" {
  value = aws_db_instance.main.endpoint
}

output "database_address" {
  value = aws_db_instance.main.address
}

output "database_port" {
  value = aws_db_instance.main.port
}

output "database_security_group_id" {
  value = aws_security_group.main.id
}
