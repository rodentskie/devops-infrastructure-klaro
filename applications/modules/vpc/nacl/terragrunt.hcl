terraform {
  source = "git::https://github.com/rodentskiedev/terraform-modules.git//resources/vpc/network_acl?ref=v0.0.11"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  environment = get_env("TG_VAR_ENVIRONMENT")
  tags_vars   = read_terragrunt_config(find_in_parent_folders("tags.hcl"))
  tags        = local.tags_vars.locals[local.environment]
}

dependency "vpc" {
  config_path = find_in_parent_folders("modules/vpc/vpc")

  mock_outputs_allowed_terraform_commands = ["validate", "init", "plan"]
  mock_outputs = {
    main = {
      id         = "vpc-123456789"
      cidr_block = "10.0.0.0/16"
    }
  }
}

inputs = {
  network_acls = {
    public = {
      vpc_id = dependency.vpc.outputs.vpcs["main"].id,
      tags = merge(
        local.tags,
        { Name = "${local.tags_vars.locals[local.environment].project}-public-nacl-${local.tags_vars.locals[local.environment].environment}" }
      )
    }
    private = {
      vpc_id = dependency.vpc.outputs.vpcs["main"].id,
      tags = merge(
        local.tags,
        { Name = "${local.tags_vars.locals[local.environment].project}-private-nacl-${local.tags_vars.locals[local.environment].environment}" }
      )
    }
  }
}