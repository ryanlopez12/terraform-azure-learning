output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "public_ip_address" {
  value = azurerm_linux_virtual_machine.my_terraform_vm.public_ip_address
}

output "tls_private_key" {
  value     = tls_private_key.example_ssh.private_key_pem
  sensitive = true
}

output "vm_managed_disk_ids" {
  description = "The id(s) of the data disks attached to the VM"
  value = {
    for k, disk-id in azurerm_managed_disk.managed_disks : k => disk-id.id
  }
}