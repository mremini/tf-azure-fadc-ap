azsubscriptionid = "" // PUT YOUR OWN

project = "fadc"
TAG = "mremini"

vnetloc="eastus2"
vnetcidr= ["10.151.3.0/24" , "10.151.4.0/24"]

vnetstopeerwith={
    "vnet1" = {name="mre_az_nocsoc_useast" , rg="cloudteam_mremini_spokes"},
    "vnet2" = {name="mre_az_spoke1_useast" , rg="cloudteam_mremini_spokes"},
    "vnet3" = {name="mre_az_spoke2_useast" , rg="cloudteam_mremini_spokes"},
    "vnet4" = {name="mre_az_hub1_useast"   , rg="cloudteam_mremini"},
}

vnetsubnets= {
"public"=       {name="public", cidr="10.151.3.0/27"},
"private"=      {name="private", cidr="10.151.3.32/27"},
"ha"=           {name="hasync", cidr="10.151.3.64/27"}

}

fadc_vmsize = "Standard_B4ms"
fadc_IMAGE_SKU= "fad-vm-byol"
fadc_VERSION = "6.1.1"
fadc_OFFER="fortinet-fortiadc"


vmbootdiagstorage= "facserial"


username = "putyourown"
password =  "putyourown"

/*
fadc=[
    {vmname="fadc1", 
    nics=[
        {name="port1", subnet="mgmt", ip="10.33.3.10"},
        {name="port2", subnet="fts_client", ip="10.33.10.10"}
    ]
    },
    {vmname="fadc2", 
    nics=[
        {name="port1", subnet="mgmt", ip="10.33.3.11"},
        {name="port2", subnet="fts_server", ip="10.33.11.11"}
    ]
    }

]
*/

extlb = "true"

fadc1={
"nic1" = {vmname="fadc1", name="port1", subnet="public", ip="10.151.3.4"},
"nic2" = {vmname="fadc1", name="port2", subnet="private", ip="10.151.3.36"},
"nic3" = {vmname="fadc1", name="port3", subnet="hasync", ip="10.151.3.68"}
}

fadc2={
"nic1" = {vmname="fadc2", name="port1", subnet="public", ip="10.151.3.5"},
"nic2" = {vmname="fadc2", name="port2", subnet="private", ip="10.151.3.37"},
"nic3" = {vmname="fadc2", name="port3", subnet="hasync", ip="10.151.3.69"}
}






