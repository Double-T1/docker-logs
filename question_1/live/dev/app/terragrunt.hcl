include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/app"
}

locals {
  root_vars = read_terragrunt_config(find_in_parent_folders("root.hcl"))
  env_vars  = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  project_full_name = "${local.root_vars.locals.project_name}-${local.env_vars.locals.environment}"
}

dependency "cloudwatch" {
  config_path = "../cloudwatch"
}

inputs = {
  project_full_name = local.project_full_name
  environment_name  = local.env_vars.locals.environment
  aws_account_id    = local.root_vars.locals.aws_account_id
  aws_region        = local.root_vars.locals.aws_region
  
  ecs_cluster = "${local.project_full_name}-cluster"
  
  # Network configuration - will use default VPC for dev
  subnets         = []  # Will be populated by data sources in module
  security_groups = []  # Will be populated by data sources in module
}