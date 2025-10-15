
variable "data_source_arn" {
  description = "Arn of the QuickSight datasource, the object containing connection metadata"
  type        = string
}

variable "database_name" {
  description = "The datasource's database name, used for tagging"
  type        = string
}

variable "view_name" {
  description = "Name of the view wrapped by this dataset"
  type        = string
}

variable "spice_config" {
  description = "Define if the dataset use SPICE or DIRECT_QUERY import mode, define refresh scheduling also."
  type = object({
    use_spice        = bool
    refresh_type     = optional(string)
    refresh_interval = optional(string)
    incremental_refresh_properties = optional(object({
      column_name = string
      size_unit   = string
      size        = number
    }))
  })
  validation {
    error_message = "if use_spice is true then refresh_type and refresh_interval are required"
    condition = (
      var.spice_config.use_spice ?
      var.spice_config.refresh_type != null && var.spice_config.refresh_interval != null
      :
      true
    )
  }
  validation {
    error_message = "if use_spice then refresh_type must be FULL_REFRESH or INCREMENTAL_REFRESH"
    condition = (
      !var.spice_config.use_spice ||
      var.spice_config.refresh_type == "FULL_REFRESH" ||
      var.spice_config.refresh_type == "INCREMENTAL_REFRESH"
    )
  }
  validation {
    error_message = "if use_spice then refresh_interval must be one of MINUTE15, MINUTE30, HOURLY, DAILY"
    condition = (
      !var.spice_config.use_spice ||
      var.spice_config.refresh_interval == "MINUTE15" ||
      var.spice_config.refresh_interval == "MINUTE30" ||
      var.spice_config.refresh_interval == "HOURLY" ||
      var.spice_config.refresh_interval == "DAILY"
    )
  }
  validation {
    error_message = "if use_spice and refresh_type == INCREMENTAL_REFRESH then incremental_refresh_properties is required"
    condition = (
      !var.spice_config.use_spice ||
      var.spice_config.refresh_type != "INCREMENTAL_REFRESH" ||
      var.spice_config.incremental_refresh_properties != null
    )
  }

  default = {
    use_spice = false
  }
}

variable "columns" {
  description = "List view's columns, it is also possible to define some computed column. The ./scripts/quicksight_dataset_export_from_aws.sh script can help to extract this configuration from quicksight."
  type = list(
    object({
      name = string
      type = string
      computed = optional(
        object({
          expression = string
        })
      )
    })
  )
}

variable "data_set_permissions" {
  description = "Dashboard permissions see ../../10-locals-permissions-constants.tf locals for some preconfigured permissions"
  type = list(
    object({
      principal = string
      actions   = list(string)
    })
  )
}

