#refer to a subnet
data "azurerm_subnet" "subnet" {
  name                 = "subnet1"
  virtual_network_name = "virtualNetwork1"
  resource_group_name  = "acceptanceTestResourceGroup1"
}

resource "azurerm_public_ip" "test" {
  name                         = "PublicIPForLB"
  location                     = "West US"
  resource_group_name          = "acceptanceTestResourceGroup1"
  public_ip_address_allocation = "static"
}

resource "azurerm_firewall" "test" {
  name                = "testfirewall"
  location            = "West US"
  resource_group_name = "acceptanceTestResourceGroup1"

  ip_configuration {
    name                          = "configuration"
    subnet_id                     = "${data.azurerm_subnet.subnet.id}"
    internal_public_ip_address_id = "${azurerm_public_ip.test.id}"
  }
}
