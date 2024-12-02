# Data block to retrieve Resource Group information
data "azurerm_resource_group" "resourcegroup01" {
  name = var.resource_group_name
}

# Data block to retrieve Virtual Network information
data "azurerm_virtual_network" "azvnet" {
  name                = "${var.vnet}"
  resource_group_name = var.vnet_rg
}

# Data block to retrieve Subnet information
data "azurerm_subnet" "subnet" {
  name                 = "${var.subnet_name}"
  resource_group_name  = var.vnet_rg
  virtual_network_name = "${data.azurerm_virtual_network.azvnet.name}"
}

# Resource block for Network Interface
resource "azurerm_network_interface" "vm_nic" {
  name                = join("", ["${var.vm_name}", "${random_id.random.dec}"])
  location            = "${data.azurerm_resource_group.resourcegroup01.location}"
  resource_group_name = "${data.azurerm_resource_group.resourcegroup01.name}"
  enable_accelerated_networking = true

  ip_configuration {
    name                          = "primary"
    subnet_id                     = "${data.azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "Dynamic"
  }
}

# Resource block for Windows Virtual Machine
resource "azurerm_windows_virtual_machine" "vm" {
  name                = var.vm_name
  resource_group_name = "${data.azurerm_resource_group.resourcegroup01.name}"
  location            = "${data.azurerm_resource_group.resourcegroup01.location}"
  size                = var.vm_size
  enable_automatic_updates = "false"
  patch_mode = "Manual"
  admin_username = var.admin_username
  admin_password = var.admin_password
  timezone = var.vm_timezone
  custom_data = "${filebase64("${path.module}/files/winrm.ps1)}"
  
  network_interface_ids = [
    azurerm_network_interface.vm_nic.id,
  ]
  os_disk {
    name = join("_", [var.vm_name, "OsDisk"])
    caching = "ReadWrite"
    storage_account_type = var.storage_account_type
  }

# Adding additional unattend content for VM customization
  additional_unattend_content {
    content = local.auto_logon_data
    setting = "AutoLogon"
  }

  additional_unattend_content {
    content = local.first_logon_data
    setting = "FirstLogonCommands"
  }

# Source image reference for the Windows VM
  source_image_reference {
    publisher = "MicrosoftWindowsDesktop"
    offer     = "windows-10"
    sku       = "win10-22h2-ent-g2"
    version   = "latest"
  }
}

# Managed Disk Resource
resource "azurerm_managed_disk" "datadisk" {
  name                 = join("_", [var.vm_name, "WriteCache"])
  resource_group_name  = data.azurerm_resource_group.resourcegroup01.name
  location             = data.azurerm_resource_group.resourcegroup01.location
  storage_account_type = var.storage_account_type
  disk_size_gb         = "16"
  create_option        = "Empty"
}

# Attach Managed Disk to Virtual Machine
resource "azurerm_virtual_machine_data_disk_attachment" "datadisk" {
  count               = 1
  virtual_machine_id  = azurerm_windows_virtual_machine.vm.id
  managed_disk_id     = azurerm_managed_disk.datadisk.id
  lun                 = format("%d", count.index)
  caching             = "ReadWrite"
}

resource "azurerm_virtual_machine_extension" "run-ps" {
  name                 = "run-ps"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"
  settings = <<SETTINGS
  {
  "commandToExecute": "powershell.exe -Command \"${local.powershell_command}\""
  }
SETTINGS
}

resource "azurerm_virtual_machine_extension" "domjoin" {
  name                 = "domjoin"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm.id
  publisher            = "Microsoft.Compute"
  type                 = "JsonADDomainExtension"
  type_handler_version = "1.3"

  # Explanation of settings: https://docs.microsoft.com/en-us/windows/desktop/api/lmjoin/nf-lm
  settings = <<SETTINGS
  {
    "Name": "${var.ad_domain_name}",
    "OUPath": "${var.ad_ou_location}",
    "User": "${var.domain_username}",
    "Restart": "true",
    "Options": "3"
  }
SETTINGS
  protected_settings = <<PROTECTED_SETTINGS
  {
  "Password": "${var.domain_password}"
  }
PROTECTED_SETTINGS
}
