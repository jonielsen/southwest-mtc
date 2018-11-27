# Create Resource Groups
resource "azurerm_resource_group" "resource-group-global" {
  name     = "rgp-global-contoso-dev"
  location = "Central US"
}

resource "azurerm_resource_group" "resource-group-westus" {
  name     = "rgp-westus-contoso-dev"
  location = "West US"
}

resource "azurerm_resource_group" "resource-group-eastus" {
  name     = "rgp-eastus-contoso-dev"
  location = "East US"
}


# Create App Service Plans
resource "azurerm_app_service_plan" "app-service-plan-westus" {
  name                = "asp-westus-contoso-dev"
  location            = "${azurerm_resource_group.resource-group-westus.location}"
  resource_group_name = "${azurerm_resource_group.resource-group-westus.name}"

  sku {
    tier = "Free"
    size = "F1"
  }
}

resource "azurerm_app_service_plan" "app-service-plan-eastus" {
  name                = "asp-eastus-contoso-dev"
  location            = "${azurerm_resource_group.resource-group-eastus.location}"
  resource_group_name = "${azurerm_resource_group.resource-group-eastus.name}"

  sku {
    tier = "Free"
    size = "F1"
  }
}

# Create App Services
resource "azurerm_app_service" "app-service-westus" {
  name                = "as-westus-contoso-dev"
  location            = "${azurerm_resource_group.resource-group-westus.location}"
  resource_group_name = "${azurerm_resource_group.resource-group-westus.name}"
  app_service_plan_id = "${azurerm_app_service_plan.app-service-plan-westus.id}"
}

resource "azurerm_app_service" "app-service-eastus" {
  name                = "as-eastus-contoso-dev"
  location            = "${azurerm_resource_group.resource-group-eastus.location}"
  resource_group_name = "${azurerm_resource_group.resource-group-eastus.name}"
  app_service_plan_id = "${azurerm_app_service_plan.app-service-plan-eastus.id}"
}

data "azurerm_virtual_network" "test" {
  name                = "virtualNetwork1"
  resource_group_name = "acceptanceTestResourceGroup1"
}

data "azurerm_subnet" "subnet" {
  name                 = "subnet1"
  virtual_network_name = "virtualNetwork1"
  resource_group_name  = "acceptanceTestResourceGroup1"
}

resource "azurerm_public_ip" "test" {
  name                         = "example-pip"
  resource_group_name          = "acceptanceTestResourceGroup1"
  location                     = "West US"
  public_ip_address_allocation = "dynamic"
}


resource "azurerm_application_gateway" "application-gateway-west" {
  name                = "ag-westus-contoso"
  resource_group_name = "acceptanceTestResourceGroup1"
  location            = "West US"


  sku {
    name     = "WAF_Medium"
    tier     = "WAF"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "subnet"
    subnet_id = "${data.azurerm_subnet.subnet.id}"
  }

  frontend_port {
    name = "http"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontend"
    public_ip_address_id = "${azurerm_public_ip.test.id}"
  }


  http_listener {
    name                           = "http"
    frontend_ip_configuration_name = "frontend"
    frontend_port_name             = "http"
    protocol                       = "Http"
  }

  probe {
    name                = "probe"
    protocol            = "http"
    path                = "/"
    host                = "contoso.com"
    interval            = "30"
    timeout             = "30"
    unhealthy_threshold = "3"
  }

   backend_address_pool {
    name        = "AppService"
    "fqdn_list" = ["${azurerm_app_service.app-service-eastus.name}.azurewebsites.net"]
   }

  backend_http_settings {
    name                  = "http"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 1
    probe_name            = "probe"
  }

  request_routing_rule {
    name                       = "http"
    rule_type                  = "Basic"
    http_listener_name         = "http"
    backend_address_pool_name  = "Appservice"
    backend_http_settings_name = "http"
  }
}
