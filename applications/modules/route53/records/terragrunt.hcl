terraform {
  source = "git::https://github.com/rodentskiedev/terraform-modules.git//resources/route53/record?ref=v0.0.18"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "alb" {
  config_path = find_in_parent_folders("modules/lb/alb")

  mock_outputs_allowed_terraform_commands = ["validate", "init", "plan"]
  mock_outputs = {
    load_balancers = {
      public = {
        arn      = "arn:aws:elasticloadbalancing:123456789"
        dns_name = "elb.amazonaws.com"
      }
    }
  }
}

dependency "hosted_zone" {
  config_path = find_in_parent_folders("modules/route53/hosted_zone")

  mock_outputs_allowed_terraform_commands = ["validate", "init", "plan"]
  mock_outputs = {
    hosted_zones = {
      default = {
        id   = "Z01231DQW665"
        arn  = "arn:aws:route53:::hostedzone/Z01231DQW665"
        name = "domain.com"
      }
    }
  }
}


inputs = {
  records = {
    api-a = {
      zone_id = dependency.hosted_zone.outputs.hosted_zones["default"].id
      name    = "api.klaro.rodentskie.com"
      type    = "CNAME"
      ttl     = 300
      values  = [dependency.alb.outputs.load_balancers.public.dns_name]
    }
  }
}