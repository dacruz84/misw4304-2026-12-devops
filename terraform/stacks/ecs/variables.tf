variable "region" {
  description = "AWS Region donde se desplegaran los recursos."
  type        = string
  nullable    = false
}

variable "owner" {
  description = "Dueno de los recursos. Para proposito academico."
  type        = string
  nullable    = false
}

variable "cluster_name" {
  description = "Nombre del ECS cluster."
  type        = string
}

variable "service_name" {
  description = "Nombre del ECS service."
  type        = string
}

variable "container_name" {
  description = "Nombre del contenedor. Debe coincidir con imagedefinitions.json del buildspec."
  type        = string
}

variable "image_uri" {
  description = "URI completo de la imagen ECR (se usa solo para el despliegue inicial)."
  type        = string
}

variable "container_port" {
  description = "Puerto del contenedor."
  type        = number
  default     = 5000
}

variable "cpu" {
  description = "CPU units para la task Fargate."
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memoria en MB para la task Fargate."
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Numero de instancias del servicio."
  type        = number
  default     = 1
}

variable "ssm_database_url_arn" {
  description = "ARN del parametro SSM con la DATABASE_URL."
  type        = string
}

variable "static_token" {
  description = "Token estatico de autenticacion."
  type        = string
  sensitive   = true
}

variable "jwt_secret_key" {
  description = "Clave secreta JWT."
  type        = string
  sensitive   = true
}
