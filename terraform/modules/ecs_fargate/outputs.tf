output "cluster_name" {
  description = "Nombre del ECS cluster."
  value       = aws_ecs_cluster.main.name
}

output "cluster_arn" {
  description = "ARN del ECS cluster."
  value       = aws_ecs_cluster.main.arn
}

output "service_name" {
  description = "Nombre del ECS service."
  value       = aws_ecs_service.app.name
}

output "task_execution_role_arn" {
  description = "ARN del IAM role de ejecucion de la task (necesario para pipeline)."
  value       = aws_iam_role.ecs_task_execution.arn
}
