
variable "dashboard_id" {
  description = "Dashboard id, have to be different for every database"
  type        = string
}

variable "dashboard_name" {
  description = "A human readable name for the dashboard"
  type        = string
}

variable "data_sets_arns" {
  description = "A list of data sets arns. Read the README.md file in the module root path."
  type = list(
    object({
      identifier   = string
      data_set_arn = string
    })
  )
}

variable "database_name" {
  description = "Every dashboard use data only from one environment dev/qa/.... every environment has its own database inside a cluster."
  type        = string
}


variable "dashboard_permissions" {
  description = "Dashboard permissions see ../../10-locals-permissions-constants.tf locals for some pre-configured permissions"
  type = list(
    object({
      principal = string
      actions   = list(string)
    })
  )
}

variable "dashboard_definition_file_path" {
  description = "The absolute path of the file exported from QuickSight. Read the README.md file in the module root path."
  type        = string
}

variable "deleted" {
  description = "A boolean flag useful to easily work-around destroy time provisioner limitations"
  type        = bool
  default     = false
}
