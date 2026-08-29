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
        arn  = "arn:aws:elasticloadbalancing:us-west-2:123456789012:targetgroup/my-targets/73e2d6bc24d8a067"
        name = "my-tg"
      }
      app = {
        arn  = "arn:aws:elasticloadbalancing:us-west-2:123456789012:targetgroup/my-targets/73e2d6bc24d8a067"
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
        arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:listener/app/my-load-balancer/50dc6c495c0c9188/f2f7dc8efc522ab2"
      }
      https = {
        arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:listener/app/my-load-balancer/50dc6c495c0c9188/f2f7dc8efc522ab2"
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
          type   = "host-header"
          values = ["api.koronadal.rodentskie.com"]
        }
      ]
    }
  }

  tags = local.tags

}