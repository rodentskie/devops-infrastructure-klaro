terraform {
  source = "git::https://github.com/rodentskiedev/terraform-modules.git//resources/vpc/network_acl_rule?ref=v0.0.11"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
}

dependency "nacl" {
  config_path = find_in_parent_folders("modules/vpc/nacl")

  mock_outputs_allowed_terraform_commands = ["validate", "init", "plan"]
  mock_outputs = {
    network_acls = {
      private = {
        id     = "acl-123456789"
        vpc_id = "vpc-123456789"
      }
      public = {
        id     = "acl-123456789"
        vpc_id = "vpc-123456789"
      }
    }
  }
}

inputs = {
  public_network_acl_id  = dependency.nacl.outputs.network_acls["public"].id
  private_network_acl_id = dependency.nacl.outputs.network_acls["private"].id

  public_rules = {
    ingress-all = { rule_number = 100, egress = false, protocol = "-1", rule_action = "allow", cidr_block = "0.0.0.0/0" }
    egress-all  = { rule_number = 100, egress = true, protocol = "-1", rule_action = "allow", cidr_block = "0.0.0.0/0" }
  }

  private_rules = {
    ingress-all = { rule_number = 100, egress = false, protocol = "-1", rule_action = "allow", cidr_block = "0.0.0.0/0" }
    egress-all  = { rule_number = 100, egress = true, protocol = "-1", rule_action = "allow", cidr_block = "0.0.0.0/0" }
  }
}