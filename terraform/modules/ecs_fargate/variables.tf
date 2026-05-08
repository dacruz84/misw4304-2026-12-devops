variable "cluster_name" {
  description = "Nombre del ECS cluster."
  type        = string
}

variable "service_name" {
  description = "Nombre del ECS service y familia de la task definition."
  type        = string
}

variable "container_name" {
  description = "Nombre del contenedor en la task definition. Debe coincidir con imagedefinitions.json."
  type        = string
}

variable "image_uri" {
  description = "URI completo de la imagen Docker en ECR (incluye tag inicial)."
  type        = string
}

variable "container_port" {
  description = "Puerto que expone el contenedor."
  type        = number
  default     = 5000
}

variable "cpu" {
  description = "CPU units para la task (256 = 0.25 vCPU)."
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memoria en MB para la task."
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Numero de instancias del servicio."
  type        = number
  default     = 1
}

variable "ssm_database_url_arn" {
  description = "ARN del parametro SSM que contiene la DATABASE_URL de PostgreSQL."
  type        = string
}

variable "static_token" {
  description = "Token estatico de autenticacion (STATIC_TOKEN)."
  type        = string
  sensitive   = true
}

variable "jwt_secret_key" {
  description = "Clave secreta para JWT (JWT_SECRET_KEY)."
  type        = string
  sensitive   = true
}

variable "region" {
  description = "AWS region para los logs de CloudWatch."
  type        = string
  nullable    = false
}
