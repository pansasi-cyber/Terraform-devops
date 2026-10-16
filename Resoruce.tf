resource "azurerm_resource_group" "Test" {
  name     = "Test-RG"
  location = "East US"
}

resource "azurerm_virtual_network" "VNET" {
  name                = "VNET_EastUS"
  address_space       = ["10.0.0.0/16"]
 location                   = azurerm_resource_group.Test.location
 resource_group_name  = azurerm_resource_group.Test.name
}

resource "azurerm_subnet" "new" {
  name                 = "subnet-EastUS"
  resource_group_name  = azurerm_resource_group.Test.name
  virtual_network_name = azurerm_virtual_network.VNET.name
  address_prefixes     = ["10.0.2.0/24"]
}
resource "azurerm_network_interface" "NI1" {
  name                = "First-nic"
  location            = azurerm_resource_group.Test.location
  resource_group_name = azurerm_resource_group.Test.name

  # Primary IP Configuration
  ip_configuration {
    name                          = "Internal-IP"
    subnet_id                     = azurerm_subnet.new.id
    private_ip_address_allocation = "Dynamic"
    primary                       = true # Sets this as the primary configuration
  }

  # Secondary IP Configuration
  ip_configuration {
    name                          = "External-IP"
    subnet_id                     = azurerm_subnet.new.id
    public_ip_address_id          = azurerm_public_ip.pub-ip.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.2.10"
    primary                       = false # Sets this as a secondary configuration 
  }
}

resource "azurerm_public_ip" "pub-ip" {
  name                = "New_Public_Ip1"
  resource_group_name = azurerm_resource_group.Test.name
  location            = azurerm_resource_group.Test.location
  allocation_method   = "Static"

  tags = {
    environment = "Production"
  }
}


resource "azurerm_network_security_group" "new-nsg" {
  name                = "prod-network_Security"
  location            = azurerm_resource_group.Test.location
  resource_group_name = azurerm_resource_group.Test.name

  security_rule {
    name                       = "rule1"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}

resource "azurerm_network_interface_security_group_association" "NSG_attach" {
  network_interface_id = azurerm_network_interface.NI1.id
  network_security_group_id = azurerm_network_security_group.new-nsg.id
}

resource "azurerm_managed_disk" "md" {
  name                 = "new-managed_disk"
  location             = azurerm_resource_group.Test.location
  resource_group_name  = azurerm_resource_group.Test.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1"

  tags = {
    environment = "Production"
  }
}
resource "azurerm_virtual_machine_data_disk_attachment" "attach_disk" {
  managed_disk_id    = azurerm_managed_disk.md.id
  virtual_machine_id = azurerm_windows_virtual_machine.win-vm.id
  lun                = "10"
  caching            = "ReadWrite"
}

resource "azurerm_windows_virtual_machine" "win-vm" {
  name                = "Win2016-DC"
  resource_group_name = azurerm_resource_group.Test.name
  location            = azurerm_resource_group.Test.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"
  network_interface_ids = [
    azurerm_network_interface.NI1.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}
