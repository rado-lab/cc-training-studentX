resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags = {
    yor_trace = "35a28c78-d63f-4208-9d0f-3bdc5bd17bfe"
  }
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-demo"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.10.0.0/16"]
  tags = {
    yor_trace = "c89d1b67-35a0-4a7d-af68-fd23c2674c15"
  }
}

resource "azurerm_subnet" "subnet" {
  name                 = "subnet-main"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.1.0/24"]
}

# ------------ NSG Ubuntu - ----------
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
  tags = {
    yor_trace = "7622fc15-0512-4123-88e1-24d9fc0b684c"
  }
}

#---instalacja agenta Cortex XDR-----

resource "azurerm_virtual_machine_extension" "cortex_linux" {
  name                       = "cortex-xdr-linux"
  virtual_machine_id         = azurerm_linux_virtual_machine.vm_ubuntu.id
  publisher                  = "Microsoft.Azure.Extensions"
  type                       = "CustomScript"
  type_handler_version       = "2.1"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    commandToExecute = <<-BASH
      bash -lc '
        set -euo pipefail

        URL="https://xdr-agents-tests.s3.eu-central-1.amazonaws.com/linux-0126_sh.tar.gz"
        WORKDIR="/tmp/cortex-xdr"
        mkdir -p "$WORKDIR"
        cd "$WORKDIR"

        echo "[*] Downloading Linux agent..."
        curl -fsSL "$URL" -o agent.tar.gz

        echo "[*] Extracting..."
        tar xzf agent.tar.gz

        echo "[*] Preparing config dir..."
        sudo mkdir -p /etc/panw

        # Skopiuj cortex.conf jeśli jest w paczce (wg docs)
        if [ -f "$WORKDIR/cortex.conf" ]; then
          sudo cp "$WORKDIR/cortex.conf" /etc/panw/cortex.conf
        elif ls "$WORKDIR"/*/cortex.conf >/dev/null 2>&1; then
          sudo cp "$WORKDIR"/*/cortex.conf /etc/panw/cortex.conf
        fi

        echo "[*] Locating installer..."
        INSTALLER="$(find "$WORKDIR" -maxdepth 2 -type f -name "cortex-*.sh" | head -n 1)"
        if [ -z "$INSTALLER" ]; then
          echo "ERROR: Nie znalazłem cortex-*.sh w paczce."
          find "$WORKDIR" -maxdepth 2 -type f -print
          exit 1
        fi

        echo "[*] chmod +x installer..."
        chmod +x "$INSTALLER"

        echo "[*] Running installer (root)..."
        sudo "$INSTALLER"

        echo "[*] Done. (Optional) Status:"
        if [ -x /opt/traps/bin/cytool ]; then
          sudo /opt/traps/bin/cytool checkin || true
          sudo /opt/traps/bin/cytool runtime query || true
        fi
      '
    BASH
  })
  tags = {
    yor_trace = "cd289de4-eeea-4728-b056-190fb46ff381"
  }
}



# ---------- NSG Windows -----------
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
  tags = {
    yor_trace = "84099b8a-5de6-4195-a601-3dda84f1141d"
  }
}

# ---------- Public IP Ubuntu ----------
resource "azurerm_public_ip" "pip_ubuntu" {
  name                = "pip-ubuntu"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = {
    yor_trace = "2a9b067c-0897-4d52-ad0a-f299346417d4"
  }
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
  tags = {
    yor_trace = "75fbfa58-822a-459c-80c1-2d7f8cfff6d8"
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
  tags = {
    yor_trace = "7c3c867d-d6fe-4a99-a25b-842d8c60cc60"
  }
}

#----instalacja agenta XDR 

resource "azurerm_virtual_machine_extension" "cortex_windows" {
  name                       = "cortex-xdr-windows"
  virtual_machine_id         = azurerm_windows_virtual_machine.vm_windows.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    commandToExecute = <<-POWERSHELL
      powershell -ExecutionPolicy Bypass -NoProfile -Command "
        $ErrorActionPreference = 'Stop';
        $url  = 'https://xdr-agents-tests.s3.eu-central-1.amazonaws.com/windows-0126_x64.msi';
        $out  = 'C:\\Windows\\Temp\\cortexxdr.msi';
        $log  = 'C:\\Windows\\Temp\\cortexxdr-install.log';

        Write-Host '[*] Downloading Cortex XDR MSI...';
        Invoke-WebRequest -Uri $url -OutFile $out;

        Write-Host '[*] Installing...';
        Start-Process msiexec.exe -ArgumentList @('/i', $out, '/qn', '/l*v', $log) -Wait;

        Write-Host '[*] Done';
      "
    POWERSHELL
  })
  tags = {
    yor_trace = "2e0b12f2-07b4-4211-8c97-731e63b878af"
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
  tags = {
    yor_trace = "0eff6a56-36b5-4c3e-b6fb-3bf4651270ff"
  }
}

resource "azurerm_network_interface_security_group_association" "assoc_windows" {
  network_interface_id      = azurerm_network_interface.nic_windows.id
  network_security_group_id = azurerm_network_security_group.nsg_windows.id
}


# ---------- Windows VM ----------
resource "azurerm_windows_virtual_machine" "vm_windows" {
  name                = "vm-windows"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B2s"

  admin_username = var.admin_username
  admin_password = var.windows_admin_password

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
  tags = {
    yor_trace = "2c018fe3-4b22-4fd0-9bf6-46140df5ef88"
  }
}
