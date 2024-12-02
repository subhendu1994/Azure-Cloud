variable "resource_group_name" {}
variable "vm_name" {}
variable "admin_username" {
    type = string
    default = "Install"
}
variable "admin_password" {
    type = string
    sensitive = true
}
variable "ad_domain_name" {}
variable "ad_ou_location" {}
variable "domain_username" {}
variable "domain_techuser" {}
variable "domain_password" {
  type = string
  sensitive = true
}

variable "subnet_name" {}
variable "vnet" {}
variable "vnet_rg" {}

variable "vm_size" {
    type = string
    default = "Standard_D2s_v5"
}

variable "vm_timezone" {
  type = string
  default = "W. Europe Standard Time"
}

variable "storage_account_name" {
  type = string
  default = "Premium_LRS"
}