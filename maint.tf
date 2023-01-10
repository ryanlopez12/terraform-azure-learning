locals {
  vm_name = "${random_string.vm-name.result}-vm"
}

locals {
  data_disks = var.vm_data_disks == null ? {} : var.vm_data_disks

  lun_map = [for key, value in local.data_disks : {
    datadisk_name = format("${local.vm_name}-DSK-%02d", key)
    lun           = tonumber(key)
  }]

  luns = { for k in local.lun_map : k.datadisk_name => k.lun }
}



resource "random_string" "vm-name" {
  length  = 12
  upper   = false
  numeric = false
  lower   = true
  special = false
}

resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = random_pet.rg_name.id
}

resource "azurerm_virtual_network" "my_terraform_network" {
  name                = "myVnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "my_terraform_subnet" {
  name                 = "mySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.my_terraform_network.name
  address_prefixes     = ["10.0.1.0/24"]
}


resource "azurerm_public_ip" "my_terraform_public_ip" {
  name                = "myPublicIP"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}


resource "azurerm_network_security_group" "my_terraform_nsg" {
  name                = "myNetworkSecurityGroup"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}


resource "azurerm_network_interface" "my_terraform_nic" {
  name                = "myNIC"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.my_terraform_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.my_terraform_public_ip.id
  }
}

resource "azurerm_network_interface_security_group_association" "example" {
  network_interface_id      = azurerm_network_interface.my_terraform_nic.id
  network_security_group_id = azurerm_network_security_group.my_terraform_nsg.id
}

# Generate random text for a unique storage account name
resource "random_id" "random_id" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.rg.name
  }

  byte_length = 8
}

resource "azurerm_storage_account" "my_storage_account" {
  name                     = "diag${random_id.random_id.hex}"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create virtual machine
resource "azurerm_linux_virtual_machine" "my_terraform_vm" {
  name                  = local.vm_name
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.my_terraform_nic.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "myOsDisk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = local.vm_name
  admin_username                  = "azureuser"
  disable_password_authentication = true



  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.example_ssh.public_key_openssh
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.my_storage_account.primary_blob_endpoint
  }
}

resource "azurerm_managed_disk" "managed_disks" {
  for_each = local.data_disks

  name                 = format("${local.vm_name}-DSK-%02d", each.key)
  disk_size_gb         = each.value
  resource_group_name  = "my_resource_group"
  location             = "westus2"
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
}

resource "azurerm_virtual_machine_data_disk_attachment" "disk_attach" {
  for_each = length(azurerm_managed_disk.managed_disks) < 1 ? {} : azurerm_managed_disk.managed_disks

  virtual_machine_id = local.vm_name
  managed_disk_id    = azurerm_managed_disk.managed_disks[each.key].id
  caching            = "ReadWrite"
  lun                = lookup(local.luns, format("${local.vm_name}-DSK-%02d", each.key))
}
# provider "azurerm" {
#   version = "3.37.0"
#   features {}
# }

# variable "cnt" {
#   default     = 1
#   description = "instances to be created"
# }
# variable "managed_disks" {
#   type    = list(map(string))
#   default = []
# }

# resource "azurerm_managed_disk" "default" {
#   count                = length(var.managed_disks) > 0 ? (length(var.managed_disks) * var.cnt) : 0
#   name                 = "${var.name}-md-${count.index % var.cnt}-${count.index % length(var.managed_disks)}"
#   location             = var.location
#   resource_group_name  = var.resource_group
#   storage_account_type = coalesce(var.managed_disks[count.index % length(var.managed_disks)].storage_account_type, "Standard_LRS")
#   create_option        = "Empty"
#   disk_size_gb         = coalesce(var.managed_disks[count.index % length(var.managed_disks)].disk_size_gb, "64")


# }
# resource "azurerm_virtual_machine_data_disk_attachment" "default" {
#   count              = length(var.managed_disks) > 0 ? (length(var.managed_disks) * var.cnt) : 0
#   managed_disk_id    = azurerm_managed_disk.default[count.index].id
#   virtual_machine_id = azurerm_linux_virtual_machine.default[count.index % var.cnt].id
#   lun                = 1 + count.index
#   caching            = "ReadWrite"
# }