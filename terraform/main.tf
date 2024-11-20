
# IBM Cloud
terraform {
  required_version = ">=1.0.0, <2.0"
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
    }
  }
}
variable "ibmcloud_key" {
  type = string
  description = "Key IBMCloud"
}

provider "ibm" {
  ibmcloud_api_key = "${var.ibmcloud_key}"
  region           = "us-south"
  zone             = "dal10"
}

data "ibm_pi_catalog_images" "catalog_images" {
  pi_cloud_instance_id = ibm_pi_workspace.powervs_service_instance.id
}

data "ibm_pi_images" "cloud_instance_images" {
  pi_cloud_instance_id = ibm_pi_workspace.powervs_service_instance.id
}

locals {
  #  stock_image_name = "RHEL9-SP2"
  stock_image_name = "CentOS-Stream-9"
  catalog_image = [for x in data.ibm_pi_catalog_images.catalog_images.images : x if x.name == local.stock_image_name]
  private_image = [for x in data.ibm_pi_images.cloud_instance_images.image_info : x if x.name == local.stock_image_name]
  private_image_id = length(local.private_image) > 0 ? local.private_image[0].id  : ""
}


# Crear Resource
resource "ibm_resource_group" "group" {
    name     = "demo_postgresql"
  }
# Crear WorkSpace para PVS
resource "ibm_pi_workspace" "powervs_service_instance" {
    pi_name               = "demo-postgresql"
    pi_datacenter         = "us-south"
    pi_resource_group_id  = ibm_resource_group.group.id
}


# Crea Networking para PVS
resource "ibm_pi_network" "power_network" {
  #  count                = 1
  pi_network_name      = "power-network"
  pi_cloud_instance_id = ibm_pi_workspace.powervs_service_instance.id
  pi_network_type      = "pub-vlan"
  pi_cidr              = "192.168.1.0/24"

}

#Crea Networking Privada PVS
resource "ibm_pi_network" "power_network_priv" {
  #    count                = 1
    pi_network_name      = "power-network-priv"
    pi_cloud_instance_id = ibm_pi_workspace.powervs_service_instance.id
    pi_network_type      = "vlan"
    pi_cidr              = "10.168.1.0/24"
}

# ID Imagen RHEL para PVS
resource "ibm_pi_image" "power_image"  {
  pi_image_name        = "CentOS-Stream-9"
  pi_image_id          = local.catalog_image[0].image_id
  pi_cloud_instance_id = ibm_pi_workspace.powervs_service_instance.id
}

# Crea PVS
resource "ibm_pi_instance" "test-instance" {
    pi_memory             = "4"
    pi_processors         = "2"
    pi_instance_name      = "power-postgresql"
    pi_proc_type          = "shared"
    pi_image_id           = local.catalog_image[0].image_id
    pi_key_pair_name      = "name-key"
    pi_sys_type           = "s922"
    pi_cloud_instance_id  = ibm_pi_workspace.powervs_service_instance.id
    pi_pin_policy         = "none"
    pi_health_status      = "OK"
    pi_network {
      network_id = ibm_pi_network.power_network.network_id
      #      ip_address = "192.168.1.4"
    }
    pi_network {
      network_id = ibm_pi_network.power_network_priv.network_id
      #      ip_address = "10.168.1.4"
    }

}

#Crear VPC para VM
resource "ibm_is_vpc" "vpc" {
  name = "vpc-demo-postgresql"
}
#Crear subnet
resource "ibm_is_subnet" "example" {
  name            = "subnet-demo-postgresql"
  vpc             = ibm_is_vpc.vpc.id
  zone            = "us-south-1"
  ipv4_cidr_block = "10.240.0.0/24"
}

#Crear Nertwork interface
resource "ibm_is_virtual_network_interface" "example"{
    name    = "vni-demo-postgresql"
    subnet  = ibm_is_subnet.example.id
    primary_ip {
    auto_delete       = false
    address           = "10.240.0.4"
    }
}
#Traer Key SSH
data "ibm_is_ssh_key" "ssh_key" {
  name = "name-key"
}
#
# Crear VM on VPC

resource "ibm_is_instance" "website" {
  name    = "website"
  image   = "r006-cf915612-e159-4f82-b871-34f6eabfe05c"
  profile = "bx2-2x8"

    primary_network_interface {
      subnet = ibm_is_subnet.example.id
      name = "vexample-primary-att"
    }
  vpc  = ibm_is_vpc.vpc.id
  zone = "us-south-1"
  keys = [data.ibm_is_ssh_key.ssh_key.id]

  //User can configure timeouts
  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}

resource "ibm_is_instance" "db_postgresql" {
  name    = "x86-demo-postgresql"
  image   = "r006-cf915612-e159-4f82-b871-34f6eabfe05c"
  profile = "bx2-2x8"

    primary_network_interface {
      subnet = ibm_is_subnet.example.id
      name = "vexample-primary-att"
    }
  vpc  = ibm_is_vpc.vpc.id
  zone = "us-south-1"
  keys = [data.ibm_is_ssh_key.ssh_key.id]

  //User can configure timeouts
  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}

## Crear IP flotante pública para la VM PostgreSQL en VPC
resource "ibm_is_floating_ip" "public_ip" {
  name   = "public-ip-demo-postgresql"
  #  zone   = "us-south-1"
    target = ibm_is_instance.db_postgresql.primary_network_interface[0].id
}



#Regla puerto 22 PostgreSQL
resource "ibm_is_security_group_rule" "sg2_tcp_rule" {
  depends_on = [ibm_is_floating_ip.public_ip]
  group      = ibm_is_vpc.vpc.default_security_group
  direction  = "inbound"
  remote     = "0.0.0.0/0"

  tcp {
    port_min = 22
    port_max = 80
  }
}



##
# Transit gateway
# 1. Crear un Transit Gateway
resource "ibm_tg_gateway" "my_tgw" {
  name     = "tg-demo-postgresql"
  location = "us-south"  # Región donde se crea el Transit Gateway
  global   = true
}

# 2. Conectar un VPC al Transit Gateway

resource "ibm_tg_connection" "vpc_connection" {
  name            = "tgw-vpc-connection"
  gateway         =  ibm_tg_gateway.my_tgw.id
  network_type    = "vpc"
  network_id      = ibm_is_vpc.vpc.resource_crn
  }

# 3. Conectar IBM Power Systems Virtual Server (PowerVS) al Transit Gateway

resource "ibm_tg_connection" "powervs_connection" {
  name            = "tgw-powervs-connection"
  gateway         = ibm_tg_gateway.my_tgw.id
  network_type    = "power_virtual_server"
  network_id      = ibm_pi_workspace.powervs_service_instance.crn  # CRN Workspace PowerVS
}
