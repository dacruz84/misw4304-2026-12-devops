output "repository_arns" {
  value = {
    for repo_name, repo_module in module.ecr_repository :
    repo_name => repo_module.repository_arn
  }
  description = "Map of repository names to their ARNs."
}