variable "TAG" {
    description = "Customer or personal Prefix TAG of the created ressources"
    type= string
} 

variable "project" {
    description = "project Prefix TAG of the created ressources"
    type= string
}

variable "azsubscriptionid"{
description = "Azure Subscription id"
}

//----------------VNET-----------

variable "vnetloc" {
    description = "Deployment Location"

}
variable "vnetcidr" {
    description = "VNET CIDRs"
    type = list(string)

}

variable "vnetstopeerwith" {
    description = "VNETs list to peer with "
}


//---------------VNET Subnets--------
variable "vnetsubnets" {
    description = "VNET Subnets names and CIDRs"
}


//---------------Azure LB--------

variable "extlb" {
    description = "Create External Azure LB or not"
    type = bool
}

//--------------------------------
variable "fadc_vmsize" {
  description = "FADC VM size"
}

variable "fadc_IMAGE_SKU" {
  description = "Azure Marketplace default image sku hourly (PAYG 'fortinet_fg-vm_payg_20190624') or byol (Bring your own license 'fortinet_fg-vm')"
}
variable "fadc_VERSION" {
  description = "FADC version by default the 'latest' available version in the Azure Marketplace is selected"
}
variable "fadc_OFFER" {
  description = "FADC version by default the 'latest' available version in the Azure Marketplace is selected"
}

//------------------------------

variable "username" {
}
variable "password" {
}

//----------------------------------VMs----------------------------

variable "fadc1" {
    description = "fadc1 Nics and IP"
}

variable "fadc2" {
    description = "fadc2 Nics and IP"
}

variable "vmbootdiagstorage" {
    description = "Storage account name "
}






