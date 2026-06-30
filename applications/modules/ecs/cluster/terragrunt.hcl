terraform {
  source = "git::https://github.com/rodentskiedev/terraform-modules.git//resources/ecs/cluster?ref=v0.0.13"
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
  clusters = {
    main = {
      container_insights = "enabled"
    }
  }

  tags = local.tags

}