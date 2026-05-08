module "pipeline" {
  source = "../../modules/pipeline"

  project_name                = var.project_name
  github_repo                 = var.github_repo
  github_branch               = var.github_branch
  ecr_repository_arn          = var.ecr_repository_arn
  image_repo_name             = var.image_repo_name
  ecs_cluster_name            = var.ecs_cluster_name
  ecs_service_name            = var.ecs_service_name
  ecs_task_execution_role_arn = var.ecs_task_execution_role_arn
  aws_account_id              = var.aws_account_id
  region                      = var.region
  owner                       = var.owner
}
