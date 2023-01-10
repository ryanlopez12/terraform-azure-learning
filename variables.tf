# variable "cnt" {
#   default     = 1
#   description = "instances to be created"
# }
# variable "managed_disks" {
#   type    = list(map(string))
#   default = []
# }

# variable "resource_group" {
#   type = string
# }

variable "resource_group_location" {
  default     = "westus2"
  description = "Location of the resource group."
}

variable "resource_group_name_prefix" {
  default     = "rg"
  description = "Prefix of the resource group name that's combined with a random ID so name is unique in your Azure subscription."
}

# variable "vm_data_disks" {
#   type = number
# }

