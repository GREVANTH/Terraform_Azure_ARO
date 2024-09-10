terraform {
  backend "remote" {
    organization = "" # Replace with your Terraform Cloud organization name
    
    workspaces {
      name = "aro-cluster-workspace" # Replace with your workspace name
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "aro_rg" {
  name     = "aro-resource-group"
  location = "East US"
}

# Virtual Network
resource "azurerm_virtual_network" "aro_vnet" {
  name                = "aro-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.aro_rg.location
  resource_group_name = azurerm_resource_group.aro_rg.name
}

# Subnet for ARO
resource "azurerm_subnet" "aro_subnet" {
  name                 = "aro-subnet"
  resource_group_name  = azurerm_resource_group.aro_rg.name
  virtual_network_name = azurerm_virtual_network.aro_vnet.name
  address_prefixes     = ["10.0.0.0/24"]
  service_endpoints    = ["Microsoft.ContainerRegistry"]
}

# Optional Subnet for Master Nodes
resource "azurerm_subnet" "aro_master_subnet" {
  name                 = "aro-master-subnet"
  resource_group_name  = azurerm_resource_group.aro_rg.name
  virtual_network_name = azurerm_virtual_network.aro_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Red Hat OpenShift Cluster
resource "azurerm_redhat_openshift_cluster" "aro_cluster" {
  name                = "aro-cluster"
  location            = azurerm_resource_group.aro_rg.location
  resource_group_name = azurerm_resource_group.aro_rg.name

  cluster_profile {
    domain = "example.com"
    resource_group_id = azurerm_resource_group.aro_rg.id
  }

  network_profile {
    vnet_cidr = azurerm_virtual_network.aro_vnet.address_space[0]
    subnet_id = azurerm_subnet.aro_subnet.id
  }

  worker_profile {
    vm_size = "Standard_D4s_v3"
    count   = 3
  }

  apiserver_profile {
    visibility = "Public"
  }

  ingress_profile {
    visibility = "Public"
  }

  tags = {
    environment = "production"
  }
}

# Output the ARO cluster details changes 2 3
output "aro_cluster_name" {
  value = azurerm_redhat_openshift_cluster.aro_cluster.name
}

output "aro_cluster_api_url" {
  value = azurerm_redhat_openshift_cluster.aro_cluster.apiserver_url
}
