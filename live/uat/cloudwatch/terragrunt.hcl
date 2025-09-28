include "root" {
  path = find_in_parent_folders("root.hcl")
}

terraform {
  source = "../../../modules/cloudwatch"
}

locals {
  # Load root configuration
  root_vars = read_terragrunt_config(find_in_parent_folders("root.hcl"))
  env_vars  = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  # Construct project name with environment
  project_full_name = "${local.root_vars.locals.project_name}-${local.env_vars.locals.environment}"
}

inputs = {
  project_full_name    = local.project_full_name
  environment_name     = local.env_vars.locals.environment
  log_retention_days   = 14  # Longer retention for UAT
  error_threshold      = 2   # Lower threshold for UAT testing
  warning_threshold    = 4
  sns_topic_arn       = ""  # Add SNS topic ARN if you want notifications
}