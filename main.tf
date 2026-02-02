resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-demo"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.10.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-main"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.1.0/24"]
}

# ---------- NSG Ubuntu - ----------
resource "azurerm_network_security_group" "nsg_ubuntu" {
  name                = "nsg-ubuntu"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.ssh_source_cidr
    destination_address_prefix = "*"
  }
}

# ---------- NSG Windows ----------
resource "azurerm_network_security_group" "nsg_windows" {
  name                = "nsg-windows"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-RDP-From-Subnet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "10.10.1.0/24"
    destination_address_prefix = "*"
  }
}

# ---------- Public IP Ubuntu ----------
resource "azurerm_public_ip" "pip_ubuntu" {
  name                = "pip-ubuntu"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# ---------- NIC Ubuntu ----------
resource "azurerm_network_interface" "nic_ubuntu" {
  name                = "nic-ubuntu"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip_ubuntu.id
  }
}

resource "azurerm_network_interface_security_group_association" "assoc_ubuntu" {
  network_interface_id      = azurerm_network_interface.nic_ubuntu.id
  network_security_group_id = azurerm_network_security_group.nsg_ubuntu.id
}

# ---------- Ubuntu VM ----------
resource "azurerm_linux_virtual_machine" "vm_ubuntu" {
  name                = "vm-ubuntu"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B2s"
  admin_username      = var.admin_username

  network_interface_ids = [azurerm_network_interface.nic_ubuntu.id]

  disable_password_authentication = true

  # KLUCZ Z VARIABLE (nie z chmury)
  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

# ---------- NIC Windows ----------
resource "azurerm_network_interface" "nic_windows" {
  name                = "nic-windows"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "assoc_windows" {
  network_interface_id      = azurerm_network_interface.nic_windows.id
  network_security_group_id = azurerm_network_security_group.nsg_windows.id
}

resource "random_password" "win_admin" {
  length  = 20
  special = true
}

# ---------- Windows VM ----------
resource "azurerm_windows_virtual_machine" "vm_windows" {
  name                = "vm-windows"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B2s"

  admin_username = var.admin_username
  admin_password = random_password.win_admin.result

  network_interface_ids = [azurerm_network_interface.nic_windows.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}
