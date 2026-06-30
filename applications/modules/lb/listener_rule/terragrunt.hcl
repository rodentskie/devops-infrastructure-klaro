terraform {
  source = "git::https://github.com/rodentskiedev/terraform-modules.git//resources/lb/listener_rule?ref=v0.0.13"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  environment = get_env("TG_VAR_ENVIRONMENT")
  tags_vars   = read_terragrunt_config(find_in_parent_folders("tags.hcl"))
  tags        = local.tags_vars.locals[local.environment]
}

dependency "tg" {
  config_path = find_in_parent_folders("modules/lb/tg")

  mock_outputs_allowed_terraform_commands = ["validate", "init", "plan"]
  mock_outputs = {
    target_groups = {
      api = {
        arn  = "arn:aws:elasticloadbalancing:123456789"
        name = "my-tg"
      }
      app = {
        arn  = "arn:aws:elasticloadbalancing:123456789"
        name = "my-tg"
      }
    }
  }
}

dependency "listener" {
  config_path = find_in_parent_folders("modules/lb/listener")

  mock_outputs_allowed_terraform_commands = ["validate", "init", "plan"]
  mock_outputs = {
    listeners = {
      http = {
        arn = "arn:aws:elasticloadbalancing:123456789"
      }
      https = {
        arn = "arn:aws:elasticloadbalancing:123456789"
      }
    }
  }
}

inputs = {
  listener_rules = {
    api = {
      listener_arn = dependency.listener.outputs.listeners["https"].arn
      priority     = 100
      action = {
        type             = "forward"
        target_group_arn = dependency.tg.outputs.target_groups["api"].arn
      }
      conditions = [
        {
          type   = "path-pattern"
          values = ["/api/*"]
        },
        {
          type   = "host-header"
          values = ["klaro.rodentskie.com"]
        }
      ]
    }
    app = {
      listener_arn = dependency.listener.outputs.listeners["https"].arn
      priority     = 200
      action = {
        type             = "forward"
        target_group_arn = dependency.tg.outputs.target_groups["app"].arn
      }
      conditions = [
        {
          type   = "host-header"
          values = ["klaro.rodentskie.com"]
        }
      ]
    }
  }

  tags = local.tags

}