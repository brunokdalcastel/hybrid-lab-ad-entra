locals {
  tags = {
    environment = var.environment
    project     = var.project
    managed_by  = "terraform"
  }
}

# --- Resource Group ---

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project}"
  location = var.location
  tags     = local.tags
}

# --- Virtual Network ---

resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub-${var.project}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = var.vnet_address_space
  tags                = local.tags
}

# --- Subnet ---

resource "azurerm_subnet" "default" {
  name                 = "snet-default"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = var.subnet_address_prefixes
}

# --- Network Security Group ---

resource "azurerm_network_security_group" "main" {
  name                = "nsg-hub-${var.project}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags
}

resource "azurerm_subnet_network_security_group_association" "default" {
  subnet_id                 = azurerm_subnet.default.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# --- Route Table ---

resource "azurerm_route_table" "main" {
  name                = "rt-hub-${var.project}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.tags
}

resource "azurerm_subnet_route_table_association" "default" {
  subnet_id      = azurerm_subnet.default.id
  route_table_id = azurerm_route_table.main.id
}

# --- Log Analytics Workspace ---

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${var.project}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_analytics_retention_days
  tags                = local.tags
}
