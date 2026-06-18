terraform {
  source = "git::https://github.com/rodentskiedev/terraform-modules.git//resources/vpc/eip?ref=v0.0.11"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  environment = get_env("TG_VAR_ENVIRONMENT")
  tags_vars   = read_terragrunt_config(find_in_parent_folders("tags.hcl"))
  tags        = local.tags_vars.locals[local.environment]
}

inputs = {
  eips = {
    nat = {
      tags = merge(
        local.tags,
        { Name = "${local.tags_vars.locals[local.environment].project}-eip-${local.tags_vars.locals[local.environment].environment}" }
      )
    }
  }
}