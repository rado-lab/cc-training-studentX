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

variable "ssh_public_key" {
  type        = string
  description = "Publiczny klucz SSH (np. ssh-ed25519 AAAA...)"
}

variable "ssh_source_cidr" {
  type        = string
  description = "CIDR skąd wolno SSH do Ubuntu"
  default     = "0.0.0.0/0"
}
