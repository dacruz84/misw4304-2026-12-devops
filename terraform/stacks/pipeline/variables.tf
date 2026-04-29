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

variable "project_name" {
  description = "Nombre del proyecto, prefijo para recursos del pipeline."
  type        = string
}

variable "github_repo" {
  description = "ID completo del repositorio GitHub (org/repo)."
  type        = string
}

variable "github_branch" {
  description = "Rama a monitorear."
  type        = string
  default     = "main"
}

variable "ecr_repository_arn" {
  description = "ARN del repositorio ECR."
  type        = string
}

variable "image_repo_name" {
  description = "Nombre del repo ECR pasado al buildspec (ej: n2d/blacklist)."
  type        = string
}

variable "ecs_cluster_name" {
  description = "Nombre del ECS cluster destino."
  type        = string
}

variable "ecs_service_name" {
  description = "Nombre del ECS service destino."
  type        = string
}

variable "ecs_task_execution_role_arn" {
  description = "ARN del IAM role de ejecucion de la task ECS (output del stack ecs)."
  type        = string
}

variable "aws_account_id" {
  description = "ID de la cuenta AWS."
  type        = string
}
