# resource "azurerm_managed_disk" "app_managed_disk" {

#   count = length(var.data_disk_names)

#   name = " var.apphostname−{var.data_disk_names[count.index %length(var.data_disk_names)]}"

#   location = azurerm_resource_group.poc_rg.location

#   resource_group_name = azurerm_resource_group.poc_rg.name

#   storage_account_type = var.app_disk_type

#   create_option = "Empty"

#   disk_size_gb = var.data_disk_sizes[count.index % length(var.data_disk_sizes)]

# }

# resource "azurerm_virtual_machine_data_disk_attachment" "app_disk_attach" {

#   count = length(var.data_disk_names)

#   vm_count = length(var.vm_app_name)

#   managed_disk_id = azurerm_managed_disk.app_managed_disk[count.index % length(azurerm_managed_disk.app_managed_disk)].id

#   virtual_machine_id = azurerm_linux_virtual_machine.app-vm-pas[0].id

#   lun = count.index + 1

#   caching = "ReadWrite"

# }


# variable "cnt" {
#   default     = 1
#   description = "instances to be created"
# }
# variable "managed_disks" {
#   type    = list(map(string))
#   default = []
# }
# #cnt=2
# #managed_disks = [{
# #    storage_account_type : "Premium_LRS"
# #    disk_size_gb : "256"
# #  }]
# resource "azurerm_managed_disk" "default" {
#   count                = length(var.managed_disks) > 0 ? (length(var.managed_disks) * var.cnt) : 0
#   name                 = "${var.name}-md-${count.index % var.cnt}-${count.index % length(var.managed_disks)}"
#   location             = var.location
#   resource_group_name  = var.resource_group
#   storage_account_type = coalesce(var.managed_disks[count.index % length(var.managed_disks)].storage_account_type, "Standard_LRS")
#   create_option        = "Empty"
#   disk_size_gb         = coalesce(var.managed_disks[count.index % length(var.managed_disks)].disk_size_gb, "64")

#   tags = merge(
#     var.tags,
#     {
#     }
#   )
# }
# resource "azurerm_virtual_machine_data_disk_attachment" "default" {
#   count              = length(var.managed_disks) > 0 ? (length(var.managed_disks) * var.cnt) : 0
#   managed_disk_id    = azurerm_managed_disk.default[count.index].id
#   virtual_machine_id = azurerm_linux_virtual_machine.default[count.index % var.cnt].id
#   lun                = 1 + count.index
#   caching            = "ReadWrite"
# }