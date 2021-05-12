
//############################ Create Resource Group ##################

resource "azurerm_resource_group" "RG" {
  name     = "${var.TAG}-${var.project}"
  location = var.vnetloc
}




//############################ Create VNETs  ##################

resource "azurerm_virtual_network" "vnetperftest" {
  name                =   "${var.TAG}-${var.project}-vnet-${var.vnetloc}"
  location            =   var.vnetloc
  resource_group_name =   azurerm_resource_group.RG.name
  address_space       =   var.vnetcidr 
  
  tags = {
    Project = "${var.project}"
  }
}


//############################ Create VNET Subnets ##################

resource "azurerm_subnet" "vnetsubnets" {
  for_each = var.vnetsubnets 

  name                =   "${var.TAG}-${var.project}-subnet-${each.value.name}"
  resource_group_name =   azurerm_resource_group.RG.name
  address_prefixes    =   [ each.value.cidr ]
  virtual_network_name = azurerm_virtual_network.vnetperftest.name

}

//############################ Peer the VNET to any existing VNET ##################
  data "azurerm_virtual_network" "vnetid" {
    for_each = var.vnetstopeerwith
    name                = each.value.name
    resource_group_name = each.value.rg
  }

resource "azurerm_virtual_network_peering" "vnetperftest-to-others" {
  for_each = var.vnetstopeerwith
  name                      = "${var.TAG}-${var.project}-to-${each.value.name}"
  resource_group_name       = azurerm_resource_group.RG.name
  virtual_network_name      = azurerm_virtual_network.vnetperftest.name
  remote_virtual_network_id = data.azurerm_virtual_network.vnetid[each.key].id

   allow_virtual_network_access = true
   allow_forwarded_traffic      = true
}

resource "azurerm_virtual_network_peering" "others-to-vnetperftest" {
    for_each = var.vnetstopeerwith
    name                          = "${each.value.name}-to-${var.TAG}-${var.project}"
    resource_group_name           = data.azurerm_virtual_network.vnetid[each.key].resource_group_name
    virtual_network_name          = data.azurerm_virtual_network.vnetid[each.key].name
    remote_virtual_network_id     = azurerm_virtual_network.vnetperftest.id    
    
    allow_virtual_network_access  = true
    allow_forwarded_traffic       = true

}


//############################ Create RTB FADC ##################
resource "azurerm_route_table" "vnet_fadc_pub_RTB" {
  name                          = "${var.TAG}-${var.project}-fadc-pub_RTB"
  location                      =  var.vnetloc
  resource_group_name   =  azurerm_resource_group.RG.name
  //disable_bgp_route_propagation = false
  tags = {
    Project = "${var.project}"
  }
}

resource "azurerm_subnet_route_table_association" "vnet_pub_RTB_assoc" {
  subnet_id      =  element([for subid in azurerm_subnet.vnetsubnets: subid.id] , index([for subname in azurerm_subnet.vnetsubnets: subname.name], "mremini-fadc-subnet-public" ) )
  route_table_id = azurerm_route_table.vnet_fadc_pub_RTB.id
} 

resource "azurerm_route" "vnet_fadc_pub_RTB_default" {
  name                = "defaultInternet"
  resource_group_name   =  azurerm_resource_group.RG.name
  route_table_name      = azurerm_route_table.vnet_fadc_pub_RTB.name
  address_prefix      = "0.0.0.0/0"
  next_hop_type       = "Internet"
}

///////////////// Priv
resource "azurerm_route_table" "vnet_fadc_priv_RTB" {
  name                          = "${var.TAG}-${var.project}-fadc-priv_RTB"
  location                      =  var.vnetloc
  resource_group_name   =  azurerm_resource_group.RG.name
  //disable_bgp_route_propagation = false
  tags = {
    Project = "${var.project}"
  }
}

resource "azurerm_subnet_route_table_association" "vnet_fadc_priv_RTB_assoc" {
  subnet_id      = element([for subid in azurerm_subnet.vnetsubnets: subid.id] , index([for subname in azurerm_subnet.vnetsubnets: subname.name], "mremini-fadc-subnet-private" ) )
  route_table_id = azurerm_route_table.vnet_fadc_priv_RTB.id
}

///////////////// HA
resource "azurerm_route_table" "vnet_fadc_ha_RTB" {
  name                          = "${var.TAG}-${var.project}-fadc-ha_RTB"
  location                      =  var.vnetloc
  resource_group_name   =  azurerm_resource_group.RG.name
  //disable_bgp_route_propagation = false
  tags = {
    Project = "${var.project}"
  }
}

resource "azurerm_subnet_route_table_association" "vnet_fadc_ha_RTB_assoc" {
  subnet_id      = element([for subid in azurerm_subnet.vnetsubnets: subid.id] , index([for subname in azurerm_subnet.vnetsubnets: subname.name], "mremini-fadc-subnet-hasync" ) )
  route_table_id = azurerm_route_table.vnet_fadc_ha_RTB.id
}




//############################ Create LB ##################

resource "azurerm_public_ip" "elbpip" {
  count = var.extlb ? 1 : 0
  name                = "${var.TAG}-${var.project}-elbpip-${count.index+1}"
  location                      =  var.vnetloc
  resource_group_name   =  azurerm_resource_group.RG.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "elbs" {
  count = var.extlb ? 1 : 0
  name                = "${var.TAG}-${var.project}-elb"
  location                      =  var.vnetloc
  resource_group_name   =  azurerm_resource_group.RG.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "${var.project}-${var.TAG}-front-${count.index+1}"
    public_ip_address_id          = element(azurerm_public_ip.elbpip.*.id , count.index )
  }
}

resource "azurerm_lb_backend_address_pool" "elb_backend" {
  count = var.extlb ? 1 : 0
  name                = "${var.TAG}-${var.project}-elbpool-${count.index+1}"
  resource_group_name   =  azurerm_resource_group.RG.name
  loadbalancer_id     = element(azurerm_lb.elbs.*.id , count.index )
}

resource "azurerm_lb_probe" "elb_probe" {
  count = var.extlb ? 1 : 0
  name                = "${var.TAG}-${var.project}-elbpool-${count.index+1}"
  resource_group_name   =  azurerm_resource_group.RG.name
  loadbalancer_id     = element(azurerm_lb.elbs.*.id , count.index )
  port                = "443"
  protocol            ="Tcp"
  interval_in_seconds = "5"  
}

//////////////////Inbound LB rules

resource "azurerm_lb_rule" "elb_rule_tcp443" {
  count = var.extlb ? 1 : 0
  resource_group_name            =  azurerm_resource_group.RG.name
  loadbalancer_id                = element(azurerm_lb.elbs.*.id , count.index)
  name                           = "${var.TAG}-${var.project}-elbrule-${count.index+1}"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "${var.project}-${var.TAG}-front-${count.index+1}"
  probe_id                       = element(azurerm_lb_probe.elb_probe.*.id , count.index )
  backend_address_pool_id        = element(azurerm_lb_backend_address_pool.elb_backend.*.id , count.index )
  enable_floating_ip             = false
  disable_outbound_snat          = true
}


//////////////////Outbound NAT rules

resource "azurerm_lb_outbound_rule" "elb-outbound-1" {
  count = var.extlb ? 1 : 0
  resource_group_name     =  azurerm_resource_group.RG.name
  loadbalancer_id         =  element(azurerm_lb.elbs.*.id , count.index )
  name                    =  "${var.TAG}-${var.project}-outbound-${count.index+1}"
  protocol                =  "All"
  backend_address_pool_id =  element(azurerm_lb_backend_address_pool.elb_backend.*.id, count.index)

  frontend_ip_configuration {
    name = "${var.project}-${var.TAG}-front-${count.index+1}"
  }
}


///////////////////Associate Nics to eLB pool

resource "azurerm_network_interface_backend_address_pool_association" "elb_backend_assoc_1" {
  count = var.extlb ? 1 : 0
  network_interface_id    = element([for nicid in azurerm_network_interface.fadc1nics: nicid.id] , index([for nicname in azurerm_network_interface.fadc1nics: nicname.name], "fadc1-port1" ) )
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = element(azurerm_lb_backend_address_pool.elb_backend.*.id, count.index)
}


resource "azurerm_network_interface_backend_address_pool_association" "elb_backend_assoc_2" {
  count = var.extlb ? 1 : 0
  network_interface_id    = element([for nicid in azurerm_network_interface.fadc2nics: nicid.id] , index([for nicname in azurerm_network_interface.fadc2nics: nicname.name], "fadc2-port1" ) )
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = element(azurerm_lb_backend_address_pool.elb_backend.*.id, count.index)
}

