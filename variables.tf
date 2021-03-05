variable "group_name" {
    description = "Set Group Name "
}

variable "vm_location" {
  description = "Resource Group Location"
}

variable "hostname" {
    description = "Set VM hostname "
}

variable "username" {
  description = "Set your username for OS "
}

variable "vm_size" {
  description = "Set VM size plan: "
  default = "Standard_B1s"
}
