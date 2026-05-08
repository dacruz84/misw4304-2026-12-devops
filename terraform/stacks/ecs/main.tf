module "ecs_fargate" {
  source = "../../modules/ecs_fargate"

  cluster_name         = var.cluster_name
  service_name         = var.service_name
  container_name       = var.container_name
  image_uri            = var.image_uri
  container_port       = var.container_port
  cpu                  = var.cpu
  memory               = var.memory
  desired_count        = var.desired_count
  ssm_database_url_arn = var.ssm_database_url_arn
  static_token         = var.static_token
  jwt_secret_key       = var.jwt_secret_key
  region               = var.region
}
