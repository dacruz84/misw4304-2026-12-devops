output "codepipeline_name" {
  description = "Nombre del CodePipeline."
  value       = aws_codepipeline.main.name
}

output "codebuild_project_name" {
  description = "Nombre del proyecto CodeBuild."
  value       = aws_codebuild_project.main.name
}

output "github_connection_arn" {
  description = "ARN de la conexion CodeStar a GitHub. Debe activarse manualmente en la consola."
  value       = aws_codestarconnections_connection.github.arn
}

output "artifact_bucket" {
  description = "Nombre del bucket S3 de artefactos del pipeline."
  value       = aws_s3_bucket.artifacts.bucket
}
