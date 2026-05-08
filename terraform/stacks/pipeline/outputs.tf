output "codepipeline_name" {
  description = "Nombre del CodePipeline."
  value       = module.pipeline.codepipeline_name
}

output "codebuild_project_name" {
  description = "Nombre del proyecto CodeBuild."
  value       = module.pipeline.codebuild_project_name
}

output "github_connection_arn" {
  description = "ARN de la conexion GitHub. Activar manualmente en la consola de AWS."
  value       = module.pipeline.github_connection_arn
}

output "artifact_bucket" {
  description = "Bucket S3 de artefactos del pipeline."
  value       = module.pipeline.artifact_bucket
}
