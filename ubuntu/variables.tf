variable "master_node_count" {
    description = "The number of master nodes."
    default  = "3"
}

variable "minion_node_count" {
    description = "The number of minion nodes."
    default  = "3"
}

variable "openstack_user_name" {
    description = "The username for the Tenant."
    default  = "admin"
}

variable "openstack_tenant_name" {
    description = "The name of the Tenant."
    default  = "admin"
}

variable "openstack_password" {
    description = "The password for the Tenant."
    default  = "346f8720c8b15402dfc1a281a435571ce51bf4b6ebb7f27c659c1"
}

variable "openstack_auth_url" {
    description = "The endpoint url to connect to OpenStack."
    default  = "http://172.29.236.100:5000/v3"
}

variable "openstack_keypair" {
    description = "The keypair to be used."
    default  = "uros"
}

variable "openstack_image" {
    description = "The instance image to be used."
    default  = "bionic-server-cloudimg-amd64"
}

variable "openstack_flavor" {
    description = "The instance flavor to be used."
    default  = "medium"
}

variable "openstack_floating_ip_pool" {
    description = "The floating ip pool to be used."
    default  = "public"
}

variable "openstack_region" {
    description = "The region to be used."
    default  = "RegionOne"
}

variable "openstack_external_network" {
    description = "Openstack external network."
    default  = "public"
}

variable "management_network" {
    description = "The management subnet to be created."
    default  = "k8s_management_network"
}

variable "management_subnet" {
    description = "The management subnet to be created."
    default  = "k8s_management_subnet"
}

variable "management_subnet_cidr" {
    description = "The management subnet cidr to be created."
    default  = "10.100.100.0/24"
}

variable "external_dns_server" {
   description = "Extenal DNS servers to use on management subnet"
   default = ["1.1.1.1"]
}
