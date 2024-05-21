resource "azurerm_resource_group" "rg" {
  location = var.resource_group_location
  name     = var.respurce_group_name
}

# Create virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "my-first-terraform-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}


##################################### WEB


resource "azurerm_subnet" "web-subnet" {
  name                 = "web-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}


#create public ip(web)
resource "azurerm_public_ip" "web_public_ip" {
  name                = "Public_ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}

#open 22/8080 for everybody
resource "azurerm_network_security_group" "web-nsg" {
  name                = "web-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow_ssh"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_http"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

# Create network interface(web)
resource "azurerm_network_interface" "web_nic" {
  name                = "web_nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "web_nic_configuration"
    subnet_id                     = azurerm_subnet.web-subnet.id
    private_ip_address            = "10.0.1.10"
    private_ip_address_allocation = "Static"
    public_ip_address_id          = azurerm_public_ip.web_public_ip.id
  }
}


resource "azurerm_network_interface_security_group_association" "example" {
    network_interface_id      = azurerm_network_interface.web_nic.id
    network_security_group_id = azurerm_network_security_group.web-nsg.id
}


#virtual machine(web)
resource "azurerm_virtual_machine" "example" {
  depends_on = [ azurerm_network_interface.web_nic, azurerm_public_ip.web_public_ip, azurerm_virtual_machine.db-example ]
  name                  = "my-vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.web_nic.id]
  vm_size              = "Standard_B2s"


  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk2"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "azureuser"
    admin_username = "azureuser"
    admin_password = var.web_vm_admin_password
    
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

}


resource "null_resource" copyfiles {
  depends_on = [ azurerm_virtual_machine.example ]
  provisioner "file" {
    source      = "app.py"
    destination = "/tmp/app.py"
  }
  provisioner "file" {
    source      = "config.py"
    destination = "/tmp/config.py"
  }

  connection {
    host     = azurerm_public_ip.web_public_ip.ip_address
    type     = "ssh"
    user     = "azureuser"
    password = var.web_vm_admin_password
    agent    = "false"
  }
}

resource "null_resource" startscript {
  depends_on = [ azurerm_virtual_machine.example, null_resource.copyfiles ]
  provisioner "remote-exec" {
    inline = [ 
      "sudo apt-get update",
      "sudo apt install python3 python3-pip git -y",
      "pip install psycopg2-binary",
      "pip install flask",
      "cd /tmp",
      "python3 app.py"
     ]

  connection {
    host     = azurerm_public_ip.web_public_ip.ip_address
    type     = "ssh"
    user     = "azureuser"
    password = var.web_vm_admin_password
    agent    = "false"
    }
 }
}



########################### DB


resource "azurerm_subnet" "db-subnet" {
  name                 = "db-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}




#create public ip(db)
resource "azurerm_public_ip" "db_public_ip" {
  name                = "db_Public_ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
}


#open 5432 in db-subnet to 10.0.1.0/24 subnet
resource "azurerm_network_security_group" "db-nsg" {
  name                = "db-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow_postgres"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = "10.0.1.0/24" # כאן כתובת ה-IP של תת-הרשת שתרצה לאפשר גישה
    destination_address_prefix = "*"            # תת-הרשת של ה-VM (למשל "*")
  }

  security_rule {
    name                       = "allow_myIP"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.myIP # כאן כתובת ה-IP של תת-הרשת שתרצה לאפשר גישה
    destination_address_prefix = "*"            # תת-הרשת של ה-VM (למשל "*")
  }
}


resource "azurerm_network_interface" "db-nic" {
  name                = "db-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "db_nic_configuration"
    subnet_id                     = azurerm_subnet.db-subnet.id
    private_ip_address            = "10.0.2.10"
    private_ip_address_allocation = "Static"
    public_ip_address_id          = azurerm_public_ip.db_public_ip.id
  }
}


# Connect the security group to the db-subnet(db)
resource "azurerm_network_interface_security_group_association" "dbcon" {
    network_interface_id      = azurerm_network_interface.db-nic.id
    network_security_group_id = azurerm_network_security_group.db-nsg.id
}


#virtual machine(db)
resource "azurerm_virtual_machine" "db-example" {
  depends_on = [ azurerm_network_interface.db-nic, azurerm_public_ip.db_public_ip ]
  name                  = "my-db-vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.db-nic.id]
  vm_size              = "Standard_B2s"


  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  storage_os_disk {
    name              = "db-osdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "azureuser"
    admin_username = "azureuser"
    admin_password = var.db_admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false

  }

}



resource "null_resource" copyfile {
  depends_on = [ azurerm_virtual_machine.db-example ]
  provisioner "file" {
    source      = "postgres.sh"
    destination = "/tmp/postgres.sh"
  }

  connection {
    host     = azurerm_public_ip.db_public_ip.ip_address
    type     = "ssh"
    user     = "azureuser"
    password = var.db_admin_password
    agent    = "false"
  }
}

resource "null_resource" startscriptt {
  depends_on = [ null_resource.copyfile, azurerm_virtual_machine.db-example ]
  provisioner "remote-exec" {
    inline = [ 
      "sudo apt-get update",
      "sudo chmod +x /tmp/postgres.sh",
      "sudo bash /tmp/postgres.sh",
      "sudo apt-get update"
     ]

  connection {
    host     = azurerm_public_ip.db_public_ip.ip_address
    type     = "ssh"
    user     = "azureuser"
    password = var.db_admin_password
    agent    = "false"
    }
 }
}

################################## OUTPUTS

output "db_ip" {
  value = azurerm_public_ip.db_public_ip.ip_address
  description = "db public ip"
}


output "web_ip" {
  value = azurerm_public_ip.web_public_ip.ip_address
  description = "web public ip"
}