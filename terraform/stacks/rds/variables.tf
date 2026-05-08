variable "region" {
  description = "La region de AWS donde se desplegaran los recursos."
  type        = string
  nullable    = false
}

variable "owner" {
  description = "Dueno de los recursos. Para proposito academico."
  type        = string
  nullable    = false
}

variable "db_identifier" {
  description = "Identificador del RDS instance."
  type        = string
}

variable "db_name" {
  description = "Nombre de la base de datos inicial."
  type        = string
}

variable "db_username" {
  description = "Usuario administrador de la base de datos."
  type        = string
}

variable "db_password" {
  description = "Password del usuario administrador."
  type        = string
  sensitive   = true
}

variable "engine_version" {
  description = "Version del motor PostgreSQL."
  type        = string
  default     = "18.1"
}

variable "instance_class" {
  description = "Tipo de instancia RDS."
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Almacenamiento inicial en GB."
  type        = number
  default     = 20
}

variable "storage_type" {
  description = "Tipo de almacenamiento RDS."
  type        = string
  default     = "gp3"
}

variable "publicly_accessible" {
  description = "Habilita acceso publico al endpoint."
  type        = bool
  default     = false
}

variable "multi_az" {
  description = "Despliegue Multi-AZ."
  type        = bool
  default     = false
}

variable "backup_retention_period" {
  description = "Dias de retencion de backups."
  type        = number
  default     = 0
}

variable "skip_final_snapshot" {
  description = "Omite snapshot final al destruir."
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Protege la instancia contra eliminacion accidental."
  type        = bool
  default     = false
}

variable "service_databases" {
  description = "Lista de bases de datos por servicio a crear en la instancia (objetos con name, username, password)."
  type = list(object({
    name     = string
    username = string
    password = string
  }))
  default = []
}
