variable "cluster_name" {
}
variable "cluster_version" {
}
variable "vpc_id" {
}
# variable "public_subnets" {
# }
variable "private_subnets" {
}
# ===== Access entries principals =====
variable "bootstrap_principal_arn" {
  type        = string
  description = "Temporary bootstrap admin principal (user or role). Remove later."
  default = null
}

variable "platform_admin_role_arn" {
  type        = string
  description = "Platform admin role for cluster operations."
  default = null
}

variable "app_team_role_arn" {
  type        = string
  description = "App team edit role."
  default = null
}

variable "app_team_view_role_arn" {
  type        = string
  description = "App team view role."
  default = null
}