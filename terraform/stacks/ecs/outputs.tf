output "cluster_name" {
  description = "Nombre del ECS cluster."
  value       = module.ecs_fargate.cluster_name
}

output "service_name" {
  description = "Nombre del ECS service."
  value       = module.ecs_fargate.service_name
}

output "task_execution_role_arn" {
  description = "ARN del IAM role de ejecucion. Necesario para el stack pipeline."
  value       = module.ecs_fargate.task_execution_role_arn
}
