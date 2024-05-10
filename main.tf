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

resource "azurerm_subnet" "web-subnet" {
  name                 = "web-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  
}

resource "azurerm_subnet" "db-subnet" {
  name                 = "db-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]

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
}

#create public ip(web)
resource "azurerm_public_ip" "web_public_ip" {
  name                = "Public_ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}


# Create network interface(web)
resource "azurerm_network_interface" "web_nic" {
  name                = "web_nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "web_nic_configuration"
    subnet_id                     = azurerm_subnet.web-subnet.id
    private_ip_address_allocation = "Static"
    public_ip_address_id          = azurerm_public_ip.web_public_ip.id
  }
}


resource "azurerm_network_interface_security_group_association" "example" {
    network_interface_id      = azurerm_network_interface.web_nic.id
    network_security_group_id = azurerm_network_security_group.web-nsg.id
}


# Connect the security group to the db-subnet(db)
resource "azurerm_subnet_network_security_group_association" "db" {
  subnet_id                 = azurerm_subnet.db-subnet.id
  network_security_group_id = azurerm_network_security_group.db-nsg.id
  
}



#virtual machine(web)
resource "azurerm_virtual_machine" "example" {
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
    name              = "myosdisk1"
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

  

   connection {
        host = azurerm_public_ip.web_public_ip.ip_address
        user = "azureuser"
        type = "ssh"
        password = var.web_vm_admin_password
      
  }


   provisioner "remote-exec" {
        inline = [
          "sudo apt update && sudo apt install -y python3.11 git",
          "git clone ..........",
          "cd ..........",
          "python3.11 app.py"
        ]
    }

    provisioner "local-exec" {
      command = "echo ${azurerm_public_ip.web_public_ip.ip_address} | Out-File -FilePath IpAdresess.txt"
      
    }
  

}  



#create public ip(db)
resource "azurerm_public_ip" "db_public_ip" {
  name                = "db_Public_ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
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

#virtual machine(db)
resource "azurerm_virtual_machine" "db-example" {
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




  connection {
        host = azurerm_public_ip.db_public_ip.ip_address
        user = "azureuser"
        type = "ssh"
        password = var.db_admin_password
      
  }

  provisioner "file" {
        source = "postgres.sh"
        destination = "/tmp/postgres.sh"
    }

    
     
   provisioner "remote-exec" {
        inline = [
          "sudo apt-get update",
          "sudo chmod +x /tmp/postgres.sh",
          "sudo bash /tmp/postgres.sh"
        ]
    }

}


output "db_ip" {
  value = azurerm_public_ip.db_public_ip.ip_address
  description = "db public ip"
}


output "web_ip" {
  value = azurerm_public_ip.web_public_ip.ip_address
  description = "web public ip"
}




