output "ubuntu_public_ip" {
  value = azurerm_public_ip.pip_ubuntu.ip_address
}

output "public_storage_account_name" {
  value = azurerm_storage_account.public.name
}

output "public_container_name" {
  value = azurerm_storage_container.public.name
}
