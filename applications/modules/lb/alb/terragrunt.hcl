terraform {
  source = "git::https://github.com/rodentskiedev/terraform-modules.git//resources/lb/alb?ref=v0.0.12"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  environment = get_env("TG_VAR_ENVIRONMENT")
  tags_vars   = read_terragrunt_config(find_in_parent_folders("tags.hcl"))
  tags        = local.tags_vars.locals[local.environment]
}

dependency "subnets" {
  config_path = find_in_parent_folders("modules/vpc/subnets")

  mock_outputs_allowed_terraform_commands = ["validate", "init", "plan"]
  mock_outputs = {
    public_subnets = {
      ap-southeast-1a = {
        availability_zone = "ap-southeast-1a"
        cidr_block        = "10.0.10.0/24"
        id                = "subnet-1234"
        vpc_id            = "vpc-1234"
      }
    }
  }
}

dependency "sg" {
  config_path = find_in_parent_folders("modules/sg")

  mock_outputs_allowed_terraform_commands = ["validate", "init", "plan"]
  mock_outputs = {
    security_groups = {
      alb = {
        id   = "sg-123456789"
        name = "sg-name"
        arn  = "arn:aws:ec2:112233"
      },
      app = {
        id   = "sg-123456789"
        name = "sg-name"
        arn  = "arn:aws:ec2:112233"
      }
    }
  }
}

inputs = {
  load_balancers = {
    public = {
      internal           = false
      security_group_ids = [dependency.sg.outputs.security_groups["alb"].id]
      subnet_ids         = values(dependency.subnets.outputs.public_subnets)[*].id
    }
  }

  tags = local.tags
}