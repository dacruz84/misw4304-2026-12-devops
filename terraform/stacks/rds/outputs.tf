output "db_instance_arn" {
  description = "ARN de la instancia RDS."
  value       = module.rds_postgres.db_instance_arn
}

output "db_endpoint" {
  description = "Endpoint de conexion."
  value       = module.rds_postgres.db_endpoint
}

output "db_address" {
  description = "Direccion DNS de la instancia."
  value       = module.rds_postgres.db_address
}

output "db_port" {
  description = "Puerto del motor."
  value       = module.rds_postgres.db_port
}

output "db_name" {
  description = "Nombre de la base de datos inicial."
  value       = module.rds_postgres.db_name
}

output "service_connection_strings" {
  description = "Connection strings for service databases (sensitive)."
  value       = module.rds_postgres.service_connection_strings
  sensitive    = true
}
