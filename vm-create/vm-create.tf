resource "azurerm_resource_group" "test" {
  name     = "acceptanceTestResourceGroup1"
  location = "West US"
}

resource "azurerm_public_ip" "test" {
  name                         = "PublicIPForLB"
  location                     = "West US"
  resource_group_name          = "${azurerm_resource_group.test.name}"
  public_ip_address_allocation = "static"
}

resource "azurerm_lb" "test" {
  name                = "TestLoadBalancer"
  location            = "West US"
  resource_group_name = "${azurerm_resource_group.test.name}"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = "${azurerm_public_ip.test.id}"
  }
}

resource "azurerm_lb_rule" "test" {
  resource_group_name            = "${azurerm_resource_group.test.name}"
  loadbalancer_id                = "${azurerm_lb.test.id}"
  name                           = "LBRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.test.id}"
  probe_id                       = "${azurerm_lb_probe.test.id}"
}
  
resource "azurerm_lb_nat_rule" "test" {
  resource_group_name            = "${azurerm_resource_group.test.name}"
  loadbalancer_id                = "${azurerm_lb.test.id}"
  name                           = "SSHAccess"
  protocol                       = "Tcp"
  frontend_port                  = 3200
  backend_port                   = 22
  frontend_ip_configuration_name = "PublicIPAddress"
}

resource "azurerm_lb_probe" "test" {
  resource_group_name = "${azurerm_resource_group.test.name}"
  loadbalancer_id     = "${azurerm_lb.test.id}"
  name                = "ssh-running-probe"
  port                = 22
}

resource "azurerm_lb_backend_address_pool" "test" {
  resource_group_name = "${azurerm_resource_group.test.name}"
  loadbalancer_id     = "${azurerm_lb.test.id}"
  name                = "BackEndAddressPool"
}


#refer to a subnet
data "azurerm_subnet" "subnet" {
  name                 = "subnet1"
  virtual_network_name = "virtualNetwork1"
  resource_group_name  = "${var.resource_group}"
}

resource "azurerm_network_interface" "nic" {
    name                = "${var.prefix}"
    location            = "${var.location}"
    resource_group_name = "${var.resource_group}"
    enable_accelerated_networking = "True"

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = "${data.azurerm_subnet.subnet.id}"
        private_ip_address_allocation = "dynamic"
	}
} 

resource "azurerm_virtual_machine" "main" {
    name                  = "${var.prefix}-vm"
    location              = "${var.location}"
    resource_group_name   = "${var.resource_group}"
    network_interface_ids = ["${element(azurerm_network_interface.nic.*.id, count.index)}"]
    vm_size               = "Standard_D3_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true


  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

    storage_image_reference {
      publisher = "Canonical"
      offer     = "UbuntuServer"
      sku       = "16.04-LTS"
      version   = "latest"
  }
  storage_os_disk {
     name              = "myosdisk1"
     caching           = "ReadWrite"
     create_option     = "FromImage"
     managed_disk_type = "Standard_LRS"
  }
  os_profile {
     computer_name  = "hostname"
     admin_username = "testadmin"
     admin_password = "Password1234!"
  }

  os_profile_linux_config {
     disable_password_authentication = false
  }
}

resource "azurerm_network_interface_nat_rule_association" "nic" {
  network_interface_id  = "${azurerm_network_interface.nic.id}"
  ip_configuration_name = "myNicConfiguration"
  nat_rule_id           = "${azurerm_lb_nat_rule.test.id}"
}

resource "azurerm_network_interface_backend_address_pool_association" "test" {
  network_interface_id    = "${azurerm_network_interface.nic.id}"
  ip_configuration_name   = "myNicConfiguration"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.test.id}"
}
