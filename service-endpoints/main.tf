data "azurerm_resource_group" "testrg" {
  name = "acceptanceTestResourceGroup1"
}

data "azurerm_virtual_network" "testvnet" {
  name                = "virtualNetwork1"
  resource_group_name = "${data.azurerm_resource_group.testrg.name}"
}

data "azurerm_subnet" "testsubnet" {
  name                 = "subnet1"
  virtual_network_name = "${data.azurerm_virtual_network.testvnet.name}"
  resource_group_name  = "${data.azurerm_resource_group.testrg.name}"
}


resource "azurerm_storage_account" "testsa" {
  name                = "jnstoracct"
  resource_group_name = "${data.azurerm_resource_group.testrg.name}"

  location                 = "${data.azurerm_resource_group.testrg.location}"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  network_rules {
    ip_rules                   = ["127.0.0.1"]
    virtual_network_subnet_ids = ["${data.azurerm_subnet.testsubnet.id}"]
  }

  tags {
    environment = "staging"
  }
}
