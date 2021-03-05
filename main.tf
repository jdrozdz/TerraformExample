provider "azurerm" {
    version = "1.27.0"
}

resource "azurerm_resource_group" "group" {
    name = var.group_name
    location = var.vm_location
}

resource "azurerm_network_security_group" "nsg" {
    name                = "${azurerm_resource_group.group.name}_nsg"
    location            = var.vm_location
    resource_group_name = azurerm_resource_group.group.name

    tags = {
        environment = azurerm_resource_group.group.name
    }
}

resource "azurerm_network_security_rule" "ssh-access" {
    name                       = "${azurerm_resource_group.group.name}-SSH"
    resource_group_name        = azurerm_resource_group.group.name
    network_security_group_name = azurerm_network_security_group.nsg.name
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
}

resource "azurerm_network_security_rule" "http-access" {
    name                       = "${azurerm_resource_group.group.name}-http"
    resource_group_name        = azurerm_resource_group.group.name
    network_security_group_name = azurerm_network_security_group.nsg.name
    priority                   = 1050
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
}

resource "azurerm_network_security_rule" "hhtps-access" {
    name                       = "${azurerm_resource_group.group.name}-https"
    resource_group_name        = azurerm_resource_group.group.name
    network_security_group_name = azurerm_network_security_group.nsg.name
    priority                   = 1051
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
}

resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.group.name
    }
    byte_length = 8
}

resource "azurerm_public_ip" "public_ip" {
    name                         = "${azurerm_resource_group.group.name}-public-ip"
    location                     = var.vm_location
    resource_group_name          = azurerm_resource_group.group.name
    allocation_method            = "Dynamic"

    tags = {
        environment = azurerm_resource_group.group.name
    }
}

resource "azurerm_virtual_network" "network" {
    address_space = ["10.0.0.0/16"]
    location = var.vm_location
    name = "${azurerm_resource_group.group.name}_network"
    resource_group_name = azurerm_resource_group.group.name
}

resource "azurerm_subnet" "gateway" {
    name                 = "${azurerm_resource_group.group.name}-Gateway"
    resource_group_name  = azurerm_resource_group.group.name
    virtual_network_name = azurerm_virtual_network.network.name
    address_prefix       = "10.0.2.0/24"
}

resource "azurerm_network_interface" "nic" {
    name                = "${azurerm_resource_group.group.name}-nic"
    location            = var.vm_location
    resource_group_name = azurerm_resource_group.group.name
    network_security_group_id = azurerm_network_security_group.nsg.id

    ip_configuration {
        name                          = "${azurerm_resource_group.group.name}-nic_ip"
        subnet_id                     = azurerm_subnet.gateway.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.public_ip.id
    }

    tags = {
        environment = azurerm_resource_group.group.name
    }
}

resource "azurerm_storage_account" "storage" {
    name                = "diag${random_id.randomId.hex}"
    resource_group_name = azurerm_resource_group.group.name
    location            = var.vm_location
    account_replication_type = "LRS"
    account_tier = "Standard"

    tags = {
        environment = azurerm_resource_group.group.name
    }
}

resource "azurerm_virtual_machine" "ckziu-vm" {
    name                  = "${azurerm_resource_group.group.name}_vm"
    location              = var.vm_location
    resource_group_name   = azurerm_resource_group.group.name
    network_interface_ids = [ azurerm_network_interface.nic.id ]
    vm_size               = var.vm_size

    storage_os_disk {
        name              = "${azurerm_resource_group.group.name}_OsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    storage_image_reference {
        publisher = "Debian"
        offer     = "debian-10"
        sku       = "10"
        version   = "latest"
    }

    os_profile {
        computer_name  = var.hostname
        admin_username = var.username
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/${var.username}/.ssh/authorized_keys"
            key_data = local.public_ssh_key
        }
    }

    boot_diagnostics {
        enabled     = "true"
        storage_uri = azurerm_storage_account.storage.primary_blob_endpoint
    }

    tags = {
        environment = azurerm_resource_group.group.name
    }
}