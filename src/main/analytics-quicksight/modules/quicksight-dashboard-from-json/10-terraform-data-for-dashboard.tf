locals {
  all_tags = merge(data.aws_default_tags.current.tags, { DatabaseName = var.database_name })

  # used by bash script, transform tags definition from terraform format to AWS cli format
  all_tags_array = [for k, v in local.all_tags : {
    "Key"   = k
    "Value" = v
  }]

}

# This resource is used only for dashboard destroy; not used in the "create" phase
# becuase the update script is able to create the dashboard resource if absent.
resource "terraform_data" "dashboard_creation_and_destruction" {
  count = !var.deleted ? 1 : 0

  triggers_replace = [
    var.dashboard_id
  ]

  input = {
    dashboard_id = var.dashboard_id
  }

  provisioner "local-exec" {
    when = destroy
    environment = {
      dashboard_id = self.input.dashboard_id
    }
    command = <<EOT
      #!/bin/bash
      set -euo pipefail
      
      echo "DESTROY $${dashboard_id}"
      account_id=$( aws sts get-caller-identity --query Account --output=text )
      aws quicksight delete-dashboard --aws-account-id $${account_id} --dashboard-id $${dashboard_id} 
    EOT

    quiet = true
  }
}

# Resource triggered at every creation/update of a dashboard arguments or
# definition file content.
resource "terraform_data" "dashboard_update" {
  count = !var.deleted ? 1 : 0

  depends_on = [
    terraform_data.dashboard_creation_and_destruction
  ]

  # Trigger on any change
  triggers_replace = [
    filesha256(var.dashboard_definition_file_path),
    var.dashboard_name,
    var.dashboard_permissions,
    local.all_tags_array,
    var.data_sets_arns
  ]

  input = {
    dashboard_id                   = var.dashboard_id
    dashboard_name                 = var.dashboard_name
    dashboard_definition_file_path = var.dashboard_definition_file_path
    dashboard_permissions          = var.dashboard_permissions
    data_sets_arns                 = var.data_sets_arns
  }

  provisioner "local-exec" {
    environment = {
      dashboard_id                   = self.input.dashboard_id
      dashboard_name                 = self.input.dashboard_name
      dashboard_definition_file_path = self.input.dashboard_definition_file_path
      dashboard_permissions          = jsonencode(self.input.dashboard_permissions)
      dashboard_tags                 = jsonencode(local.all_tags_array)
      dashboard_arn                  = "arn:aws:quicksight:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:dashboard/${self.input.dashboard_id}"
      data_sets_arns                 = jsonencode(self.input.data_sets_arns)
    }
    command = file("${path.module}/scripts/quicksight_dashboard_import_to_aws.sh")

    quiet = true
  }
}
