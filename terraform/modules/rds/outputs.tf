output "db_instance_arn" {
  description = "ARN de la instancia RDS."
  value       = aws_db_instance.postgres.arn
}

output "db_endpoint" {
  description = "Endpoint de conexion."
  value       = aws_db_instance.postgres.endpoint
}

output "db_address" {
  description = "Direccion DNS de la instancia."
  value       = aws_db_instance.postgres.address
}

output "db_port" {
  description = "Puerto del motor."
  value       = aws_db_instance.postgres.port
}

output "db_name" {
  description = "Nombre de la base de datos inicial."
  value       = aws_db_instance.postgres.db_name
}

output "service_connection_strings" {
  description = "Map of connection strings for service databases (sensitive)."
  value = {
    for db in var.service_databases : db.name => format("postgresql://%s:%s@%s:%d/%s", db.username, db.password, aws_db_instance.postgres.address, aws_db_instance.postgres.port, db.name)
  }
  sensitive = true
}
