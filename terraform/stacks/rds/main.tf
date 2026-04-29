module "rds_postgres" {
  source = "../../modules/rds"

  db_identifier          = var.db_identifier
  db_name                = var.db_name
  db_username            = var.db_username
  db_password            = var.db_password
  engine_version         = var.engine_version
  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage
  storage_type           = var.storage_type
  publicly_accessible    = var.publicly_accessible
  multi_az               = var.multi_az
  backup_retention_period = var.backup_retention_period
  skip_final_snapshot     = var.skip_final_snapshot
  deletion_protection     = var.deletion_protection
  service_databases       = var.service_databases
}
