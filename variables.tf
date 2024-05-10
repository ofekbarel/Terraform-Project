variable "resource_group_location" {
  type        = string
  description = "Location of the resource group."
  default = "eastus"
}



variable "respurce_group_name" {
  type        = string
  description = "The username for the local account that will be created on the new VM."
  default = "rg"
}

variable "web_vm_admin_password" {
    type = string
    description = "the admin password"
    sensitive = true
  
}


variable "db_admin_password" {
    type = string
    description = "the db password"
    sensitive = true
  
}