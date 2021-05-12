//############################ DUT NIC  ############################


data  "azurerm_subnet" "fadc1subnetid" {
  for_each = var.fadc1
  name                 = "${var.TAG}-${var.project}-subnet-${each.value.subnet}"
  virtual_network_name = azurerm_virtual_network.vnetperftest.name
  resource_group_name  = azurerm_resource_group.RG.name
  depends_on = [
    azurerm_subnet.vnetsubnets
  ]
}
data  "azurerm_subnet" "fadc2subnetid" {
  for_each = var.fadc2
  name                 = "${var.TAG}-${var.project}-subnet-${each.value.subnet}"
  virtual_network_name = azurerm_virtual_network.vnetperftest.name
  resource_group_name  = azurerm_resource_group.RG.name
    depends_on = [
    azurerm_subnet.vnetsubnets
  ]
}


resource "azurerm_network_interface" "fadc1nics" {
  for_each = var.fadc1
  name                          = "${each.value.vmname}-${each.value.name}"
  location                      =  var.vnetloc
  resource_group_name   =  azurerm_resource_group.RG.name
  enable_ip_forwarding      = true
  enable_accelerated_networking   = false

  ip_configuration {
    name                                    = "ipconfig1"
    subnet_id                               = data.azurerm_subnet.fadc1subnetid[each.key].id
    private_ip_address_allocation           = "static"
    private_ip_address                      = each.value.ip
  }
}

resource "azurerm_network_interface" "fadc2nics" {
  for_each = var.fadc2
  name                            = "${each.value.vmname}-${each.value.name}"
  location                        = var.vnetloc
  resource_group_name             = azurerm_resource_group.RG.name
  enable_ip_forwarding            = true
  enable_accelerated_networking   = false

  ip_configuration {
    name                                    = "ipconfig1"
    subnet_id                               = data.azurerm_subnet.fadc2subnetid[each.key].id
    private_ip_address_allocation           = "static"
    private_ip_address                      = each.value.ip
  }
}


////////////////////////////////////////FADC//////////////////////////////
data "template_file" "fadc1_customdata" {
  template = file ("./assets/fadc-userdata.tpl")
  vars = {
    fadc_id              = element ( values(var.fadc1)[*].vmname , 0)
    fadc_license_file    = "./assets/fadc1.lic"
    fadc_config_ha       = true

    fadc_ha_localip      = element ( values(var.fadc1)[*].ip , 2)
    fadc_ha_peerip       = element ( values(var.fadc2)[*].ip , 2)
    fadc_ha_priority     = "5"
    fadc1_ha_nodeid      = "0"
    fadc2_ha_nodeid      = "1"
    fadc_ha_nodeid       = "0"

  }
}

data "template_file" "fadc2_customdata" {
  template = file ("./assets/fadc-userdata.tpl")
  vars = {
    fadc_id              = element ( values(var.fadc1)[*].vmname , 0)
    fadc_license_file    = "./assets/fadc2.lic"
    fadc_config_ha       = true

    fadc_ha_localip      = element ( values(var.fadc2)[*].ip , 2)
    fadc_ha_peerip       = element ( values(var.fadc1)[*].ip , 2)
    fadc_ha_priority     = "9"
    fadc1_ha_nodeid      = "0"
    fadc2_ha_nodeid      = "1"
    fadc_ha_nodeid       = "1"    

  }
}


resource "azurerm_virtual_machine" "fadc1" {
  name                         = "${var.TAG}-${var.project}-fadc1"
  location                      =  var.vnetloc
  resource_group_name           =  azurerm_resource_group.RG.name
  network_interface_ids        =  [for nic in azurerm_network_interface.fadc1nics: nic.id]
  primary_network_interface_id = element ( values(azurerm_network_interface.fadc1nics)[*].id , 0)
  vm_size                      = var.fadc_vmsize

  identity {
    type = "SystemAssigned"
  }

  storage_image_reference {
    publisher = "fortinet"
    offer     = var.fadc_OFFER
    sku       = var.fadc_IMAGE_SKU
    version   = var.fadc_VERSION
  }

  plan {
    publisher = "fortinet"
    product   = var.fadc_OFFER
    name      = var.fadc_IMAGE_SKU
  }

  storage_os_disk {
    name              = "${var.TAG}-${var.project}-fadc1_OSDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name = "${var.TAG}-${var.project}-fadc1_DataDisk"
    managed_disk_type = "Premium_LRS"
    create_option = "Empty"
    lun = 0
    disk_size_gb = "30"
  }
  os_profile {
    computer_name  = "${var.TAG}-${var.project}-fadc1"
    admin_username = var.username
    admin_password = var.password
    custom_data    = data.template_file.fadc1_customdata.rendered
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  zones = [1]

  /*boot_diagnostics {
    enabled     = true
    storage_uri = "https://${var.vmbootdiagstorage}.blob.core.windows.net/"
  } */

  tags = {
    Project = "${var.project}"
    Role = "FTNT"
  }

}


resource "azurerm_virtual_machine" "fadc2" {
  name                         = "${var.TAG}-${var.project}-fadc2"
  location                     =  var.vnetloc
  resource_group_name          =  azurerm_resource_group.RG.name
  network_interface_ids        =  [for nic in azurerm_network_interface.fadc2nics: nic.id]
  primary_network_interface_id = element ( values(azurerm_network_interface.fadc2nics)[*].id , 0)
  vm_size                      = var.fadc_vmsize

  identity {
    type = "SystemAssigned"
  }

  storage_image_reference {
    publisher = "fortinet"
    offer     = var.fadc_OFFER
    sku       = var.fadc_IMAGE_SKU
    version   = var.fadc_VERSION
  }

  plan {
    publisher = "fortinet"
    product   = var.fadc_OFFER
    name      = var.fadc_IMAGE_SKU
  }

  storage_os_disk {
    name              = "${var.TAG}-${var.project}-fadc2_OSDisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name = "${var.TAG}-${var.project}-fadc2_DataDisk"
    managed_disk_type = "Premium_LRS"
    create_option = "Empty"
    lun = 0
    disk_size_gb = "30"
  }
  os_profile {
    computer_name  = "${var.TAG}-${var.project}-fadc2"
    admin_username = var.username
    admin_password = var.password
    custom_data    = data.template_file.fadc2_customdata.rendered
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  zones = [2]

  /*boot_diagnostics {
    enabled     = true
    storage_uri = "https://${var.vmbootdiagstorage}.blob.core.windows.net/"
  } */ 

  tags = {
    Project = "${var.project}"
    Role = "FTNT"
  }

}