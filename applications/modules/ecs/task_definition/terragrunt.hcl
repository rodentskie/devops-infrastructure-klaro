terraform {
  source = "git::https://github.com/rodentskiedev/terraform-modules.git//resources/ecs/task_definition?ref=v0.0.13"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  environment = get_env("TG_VAR_ENVIRONMENT")
  tags_vars   = read_terragrunt_config(find_in_parent_folders("tags.hcl"))
  tags        = local.tags_vars.locals[local.environment]
}

dependency "iam" {
  config_path = find_in_parent_folders("modules/iam/role")

  mock_outputs_allowed_terraform_commands = ["validate", "init", "plan"]
  mock_outputs = {
    roles = {
      ecs_task = {
        arn  = "arn:aws:role:123456789"
        id   = "tmp-id"
        name = "tmp-name"
      }
    }
  }
}

inputs = {
  config_file        = "${get_terragrunt_dir()}/config/config.yml"
  execution_role_arn = dependency.iam.outputs.roles["ecs_task"].arn
  task_role_arn      = dependency.iam.outputs.roles["ecs_task"].arn

  tags = local.tags
}