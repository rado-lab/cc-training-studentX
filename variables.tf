variable "resource_group_name" {
  type    = string
  default = "rg-attack-path-hw"
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "admin_username" {
  type    = string
  default = "azureuser"
}

# To ma być PUBLICZNY klucz (z pliku ~/.ssh/id_ed25519.pub)
variable "ssh_public_key" {
  type      = string
  sensitive = true
}

# Ogranicz SSH do swojego IP, np. "1.2.3.4/32"
variable "ssh_source_cidr" {
  type    = string
  default = "0.0.0.0/0" # do labu OK; do normalnego użycia zmień na swoje IP/32
}

# Storage (public)
variable "public_storage_account_prefix" {
  type    = string
  default = "apathhw"
}

variable "public_container_name" {
  type    = string
  default = "public"
}

variable "windows_admin_password" {
  description = "Admin password for Windows VM"
  type        = string
  sensitive   = true
}

variable "linux_payload_url" {
  type        = string
  description = "Direct download URL for Linux payload"
}

variable "windows_payload_url" {
  type        = string
  description = "Direct download URL for Windows payload"
}

