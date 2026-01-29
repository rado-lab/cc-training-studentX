variable "location" {
  type    = string
  default = "polandcentral"
}

variable "resource_group_name" {
  type    = string
  default = "rg-cnseries-demo"
}

variable "admin_username" {
  type    = string
  default = "azureadmin"
}

variable "ssh_key_name" {
  type    = string
  default = "ubuntu-ssh-290126"
}

variable "ssh_key_resource_group_name" {
  type    = string
  default = "test-key-tw"
}


variable "ssh_source_cidr" {
  type        = string
  description = "CIDR skąd wolno SSH do Ubuntu"
  default     = "0.0.0.0/0"
}
