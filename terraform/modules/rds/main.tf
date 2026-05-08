terraform {
  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = ">= 1.14.0"
    }
  }
}

resource "aws_security_group" "rds" {
  name_prefix = "rds-postgres-"
  description = "Security group para RDS PostgreSQL"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "PostgreSQL desde el VPC"
    protocol    = "tcp"
    from_port   = 5432
    to_port     = 5432
    cidr_blocks = var.publicly_accessible ? ["0.0.0.0/0"] : [data.aws_vpc.default.cidr_block]
  }

  egress {
    description = "Salida a internet"
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "rds" {
  name       = "rds-default-subnets"
  subnet_ids = data.aws_subnets.all.ids
}

resource "aws_db_instance" "postgres" {
  identifier                = var.db_identifier
  engine                    = "postgres"
  engine_version            = var.engine_version
  instance_class            = var.instance_class
  allocated_storage         = var.allocated_storage
  storage_type              = var.storage_type
  db_name                   = var.db_name
  username                  = var.db_username
  password                  = var.db_password
  port                      = 5432
  publicly_accessible       = var.publicly_accessible
  multi_az                  = var.multi_az
  backup_retention_period   = var.backup_retention_period
  skip_final_snapshot       = var.skip_final_snapshot
  deletion_protection       = var.deletion_protection
  vpc_security_group_ids    = [aws_security_group.rds.id]
  db_subnet_group_name      = aws_db_subnet_group.rds.name
  apply_immediately         = true
}

# Configure postgresql provider to manage DB objects inside the created instance
provider "postgresql" {
  host     = aws_db_instance.postgres.address
  port     = aws_db_instance.postgres.port
  username = var.db_username
  password = var.db_password
  sslmode  = "require"
  superuser = false
  connect_timeout = 60
}

resource "postgresql_role" "service_roles" {
  for_each = { for db in var.service_databases : db.name => db }
  name     = each.value.username
  login    = true
  password = each.value.password
  depends_on = [aws_db_instance.postgres]
}

resource "postgresql_database" "service_dbs" {
  for_each = { for db in var.service_databases : db.name => db }
  name  = each.value.name
  owner = postgresql_role.service_roles[each.key].name
  depends_on = [postgresql_role.service_roles]
}
