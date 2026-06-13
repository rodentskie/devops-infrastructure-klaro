locals {
  region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  tags_vars   = read_terragrunt_config(find_in_parent_folders("tags.hcl"))

  environment = get_env("TG_VAR_ENVIRONMENT")
}

remote_state {
  backend = "s3"
  config = {
    encrypt        = true
    bucket         = "tg-state-${local.environment}-${local.tags_vars.locals[local.environment].project}-${local.region_vars.locals[local.environment].aws_region}"
    key            = "${path_relative_to_include()}/tf.tfstate"
    region         = local.region_vars.locals[local.environment].aws_region
    dynamodb_table = "tg-locks-${local.environment}-${local.tags_vars.locals[local.environment].project}-${local.region_vars.locals[local.environment].aws_region}"
  }
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

inputs = merge(
  local.region_vars.locals[local.environment],
  { environment = local.environment },
)