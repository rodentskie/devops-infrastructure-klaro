terraform {
  source = "git::https://github.com/rodentskiedev/terraform-modules.git//resources/acm?ref=v0.0.9"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "route53" {
  config_path = find_in_parent_folders("modules/route53/hosted_zone")

  mock_outputs_allowed_terraform_commands = ["validate", "init", "plan"]
  mock_outputs = {
    default = {
      id   = "Z01231DQW665",
      arn  = "arn:aws:route53:::hostedzone/Z01231DQW665",
      name = "domain.com"
    }
  }
}

locals {
  environment = get_env("TG_VAR_ENVIRONMENT")

  tags_vars = read_terragrunt_config(find_in_parent_folders("tags.hcl"))

  tags = local.tags_vars.locals[local.environment]
}

inputs = {
  certificates = {
    klaro = {
      domain_name               = "klaro.rodentskie.com"
      subject_alternative_names = ["*.klaro.rodentskie.com"]
      validation_method         = "DNS"
      tags                      = local.tags
    }
  }
}