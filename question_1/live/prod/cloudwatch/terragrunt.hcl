include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/cloudwatch"
}

locals {
  root_vars = read_terragrunt_config(find_in_parent_folders("root.hcl"))
  env_vars  = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  project_full_name = "${local.root_vars.locals.project_name}-${local.env_vars.locals.environment}"
}

inputs = {
  project_full_name    = local.project_full_name
  environment_name     = local.env_vars.locals.environment
  log_retention_days   = 30
  error_threshold      = 5
  warning_threshold    = 10
  sns_topic_arn       = ""  # Add SNS topic ARN for production alerts
}