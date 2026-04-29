module "ecr_repository" {
  for_each = var.repository_names
  
  source           = "../../modules/container_registry"
  keep_tags_number = var.keep_tags_number
  repository_name  = each.value
}