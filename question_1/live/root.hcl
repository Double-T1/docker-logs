# Configure Terragrunt to automatically store tfstate files in an S3 bucket
remote_state {
  backend = "s3"
  config = {
    encrypt        = true
    bucket         = "terragrunt-state-${get_aws_account_id()}-${local.aws_region}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.aws_region
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# Generate an AWS provider block from template file
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = file("${get_parent_terragrunt_dir()}/templates/provider.tf")
}

# ---------------------------------------------------------------------------------------------------------------------
# GLOBAL PARAMETERS
# These variables apply to all configurations in this subfolder.
# ---------------------------------------------------------------------------------------------------------------------

locals {
  # Global configuration - define once, use everywhere
  aws_account_id = get_aws_account_id()
  aws_region     = "us-west-2"
  project_name   = "docker-logs"

  # Common tags to apply to all resources
  common_tags = {
    Project     = local.project_name
    ManagedBy   = "Terragrunt"
    Region      = local.aws_region
  }
}