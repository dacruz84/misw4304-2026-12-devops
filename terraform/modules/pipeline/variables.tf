variable "project_name" {
  description = "Nombre del proyecto, usado como prefijo para todos los recursos."
  type        = string
}

variable "github_repo" {
  description = "ID completo del repositorio GitHub (org/repo o usuario/repo)."
  type        = string
}

variable "github_branch" {
  description = "Rama a monitorear para disparar el pipeline."
  type        = string
  default     = "main"
}

variable "ecr_repository_arn" {
  description = "ARN del repositorio ECR donde CodeBuild sube las imagenes."
  type        = string
}

variable "image_repo_name" {
  description = "Nombre del repositorio ECR (ej: n2d/blacklist). Se pasa al buildspec como env var."
  type        = string
}

variable "ecs_cluster_name" {
  description = "Nombre del ECS cluster destino del despliegue."
  type        = string
}

variable "ecs_service_name" {
  description = "Nombre del ECS service destino del despliegue."
  type        = string
}

variable "ecs_task_execution_role_arn" {
  description = "ARN del IAM role de ejecucion de la task ECS (requerido para iam:PassRole)."
  type        = string
}

variable "aws_account_id" {
  description = "ID de la cuenta AWS."
  type        = string
}

variable "region" {
  description = "Region AWS."
  type        = string
  nullable    = false
}

variable "owner" {
  description = "Dueno de los recursos. Para proposito academico."
  type        = string
  nullable    = false
}
