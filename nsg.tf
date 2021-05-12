//############################ Create FADC NSG ##################

//////MGMT
resource "azurerm_network_security_group" "fadc_nsg_priv" {
  name                  = "${var.TAG}-${var.project}-mgmt-nsg"
  location              =  var.vnetloc
  resource_group_name   =  azurerm_resource_group.RG.name
}

  
resource "azurerm_network_security_rule" "fadc_nsg_priv_rule_egress" {
  name                        = "AllOutbound"
  resource_group_name   =  azurerm_resource_group.RG.name
  network_security_group_name = azurerm_network_security_group.fadc_nsg_priv.name
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  
}
resource "azurerm_network_security_rule" "fadc_nsg_priv_rule_ingress_1" {
  name                        = "AllInbound"
  resource_group_name   =  azurerm_resource_group.RG.name
  network_security_group_name = azurerm_network_security_group.fadc_nsg_priv.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "10.0.0.0/8"
  destination_address_prefix  = "*"
  
}

//////PUB
resource "azurerm_network_security_group" "fadc_nsg_pub" {
  name                  = "${var.TAG}-${var.project}-pub-nsg"
  location              =  var.vnetloc
  resource_group_name   =  azurerm_resource_group.RG.name
}

  
resource "azurerm_network_security_rule" "fadc_nsg_pub_rule_egress" {
  name                        = "AllOutbound"
  resource_group_name   =  azurerm_resource_group.RG.name
  network_security_group_name = azurerm_network_security_group.fadc_nsg_pub.name
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  
}
resource "azurerm_network_security_rule" "fadc_nsg_pub_rule_ingress_1" {
  name                        = "AllInbound"
  resource_group_name   =  azurerm_resource_group.RG.name
  network_security_group_name = azurerm_network_security_group.fadc_nsg_pub.name
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  
}

//############################ NIC to NSG  ############################

////MGMT
resource "azurerm_network_interface_security_group_association" "fadc1priv" {
  network_interface_id      = element ([for nic in azurerm_network_interface.fadc1nics: nic.id], 1 )
  network_security_group_id = azurerm_network_security_group.fadc_nsg_priv.id
}
resource "azurerm_network_interface_security_group_association" "fadc2priv" {
  network_interface_id      = element ([for nic in azurerm_network_interface.fadc2nics: nic.id], 1 )
  network_security_group_id = azurerm_network_security_group.fadc_nsg_priv.id
}

////PUB
resource "azurerm_network_interface_security_group_association" "fadc1pub" {
  network_interface_id      = element ([for nic in azurerm_network_interface.fadc1nics: nic.id], 0 )
  network_security_group_id = azurerm_network_security_group.fadc_nsg_pub.id
}
resource "azurerm_network_interface_security_group_association" "fadc2pub" {
  network_interface_id      = element ([for nic in azurerm_network_interface.fadc2nics: nic.id], 0 )
  network_security_group_id = azurerm_network_security_group.fadc_nsg_pub.id
}