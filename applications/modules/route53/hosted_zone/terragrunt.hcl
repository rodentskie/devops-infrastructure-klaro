terraform {
  source = "git::https://github.com/rodentskiedev/terraform-modules.git//resources/route53/hosted_zone?ref=v0.0.9"
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
  hosted_zones = {
    default = {
      name    = "klaro.rodentskie.com"
      comment = "default hosted zone"
      tags    = local.tags
    }
  }
}