terraform {
  required_version = ">= 0.11.0"
}

resource "openstack_networking_router_v2" "router_1" {
  name                = "my_router"
  admin_state_up      = true
  external_network_id = "${data.openstack_networking_network_v2.openstack_external_network.id}"
}

resource "openstack_networking_router_interface_v2" "router_interface_1" {
  router_id = "${openstack_networking_router_v2.router_1.id}"
  subnet_id = "${openstack_networking_subnet_v2.management_subnet.id}"
}

# Create a management network
resource "openstack_networking_network_v2" "management_network" {
  name           = "${var.management_network}"
  admin_state_up = "true"
}


# Create a management subnet
resource "openstack_networking_subnet_v2" "management_subnet" {
  name       = "${var.management_subnet}"
  network_id = "${openstack_networking_network_v2.management_network.id}"
  cidr       = "${var.management_subnet_cidr}"
  dns_nameservers = "${var.external_dns_server}"
  ip_version = 4
}

resource "openstack_networking_secgroup_v2" "secgroup_1" {
  name        = "k8s"
  description = "k8s security group"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_1" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.secgroup_1.id}"
}

# DHCP master slave sync
resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_2" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 647
  port_range_max    = 647
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.secgroup_1.id}"
}

# PowerDNS AXFR and query
resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_3" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 53
  port_range_max    = 53
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.secgroup_1.id}"
}

# PowerDNS AXFR and query
resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_4" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 53
  port_range_max    = 53
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.secgroup_1.id}"
}

# PowerDNS API
resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_5" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8081
  port_range_max    = 8081
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.secgroup_1.id}"
}

resource "openstack_networking_floatingip_v2" "k8s_master1_floating_ip" {
  pool = "${var.openstack_floating_ip_pool}"
}

resource "openstack_compute_instance_v2" "k8s_master1_instance" {
  name            = "master1"
  image_id        = "${data.openstack_images_image_v2.openstack_image.id}"
  flavor_id       = "${data.openstack_compute_flavor_v2.openstack_flavor.id}"
  key_pair        = "${var.openstack_keypair}"

  metadata {
    group = "k8s_masters"
    groups = "k8s_masters,k8s"
  }

  network {
     name = "${openstack_networking_network_v2.management_network.name}"
  }
  depends_on = ["openstack_networking_subnet_v2.management_subnet"]
}

resource "openstack_compute_floatingip_associate_v2" "k8s_master1_floating_ip" {
  floating_ip = "${openstack_networking_floatingip_v2.k8s_master1_floating_ip.address}"
  instance_id = "${openstack_compute_instance_v2.k8s_master1_instance.id}"
  fixed_ip    = "${openstack_compute_instance_v2.k8s_master1_instance.network.0.fixed_ip_v4}"
}

resource "openstack_networking_floatingip_v2" "k8s_node1_floating_ip" {
  pool = "${var.openstack_floating_ip_pool}"
}

resource "openstack_compute_instance_v2" "k8s_node1_instance" {
  name            = "node1"
  image_id        = "${data.openstack_images_image_v2.openstack_image.id}"
  flavor_id       = "${data.openstack_compute_flavor_v2.openstack_flavor.id}"
  key_pair        = "${var.openstack_keypair}"
  #config_drive = true

  metadata {
    group = "k8s_nodes"
    groups = "k8s_nodes,k8s"
  }

  network {
      name = "${openstack_networking_network_v2.management_network.name}"
  }
  depends_on = ["openstack_networking_subnet_v2.management_subnet"]
}

resource "openstack_compute_floatingip_associate_v2" "k8s_node1_floating_ip" {
  floating_ip = "${openstack_networking_floatingip_v2.k8s_node1_floating_ip.address}"
  instance_id = "${openstack_compute_instance_v2.k8s_node1_instance.id}"
  fixed_ip    = "${openstack_compute_instance_v2.k8s_node1_instance.network.0.fixed_ip_v4}"
}

resource "openstack_networking_floatingip_v2" "k8s_node2_floating_ip" {
  pool = "${var.openstack_floating_ip_pool}"
}

resource "openstack_compute_instance_v2" "k8s_node2_instance" {
  name            = "node2"
  image_id        = "${data.openstack_images_image_v2.openstack_image.id}" 
  flavor_id       = "${data.openstack_compute_flavor_v2.openstack_flavor.id}"
  key_pair        = "${var.openstack_keypair}"
  #config_drive = true

  metadata {
    group = "k8s_nodes"
    groups = "k8s_nodes,k8s"
  }

  network {
    name = "${openstack_networking_network_v2.management_network.name}"
  }
  depends_on = ["openstack_networking_subnet_v2.management_subnet"]

}

resource "openstack_compute_floatingip_associate_v2" "k8s_node2_floating_ip" {
  floating_ip = "${openstack_networking_floatingip_v2.k8s_node2_floating_ip.address}"
  instance_id = "${openstack_compute_instance_v2.k8s_node2_instance.id}"
  fixed_ip    = "${openstack_compute_instance_v2.k8s_node2_instance.network.0.fixed_ip_v4}"
}

resource "openstack_networking_floatingip_v2" "k8s_node3_floating_ip" {
  pool = "${var.openstack_floating_ip_pool}"
}

resource "openstack_compute_instance_v2" "k8s_node3_instance" {
  name            = "node3"
  image_id        = "${data.openstack_images_image_v2.openstack_image.id}"
  flavor_id       = "${data.openstack_compute_flavor_v2.openstack_flavor.id}"
  key_pair        = "${var.openstack_keypair}"
  #config_drive = true

  metadata {
    group = "k8s_nodes"
    groups = "k8s_nodes,k8s"
  }

  network {
    name = "${openstack_networking_network_v2.management_network.name}"
  }
  depends_on = ["openstack_networking_subnet_v2.management_subnet"]
}

resource "openstack_compute_floatingip_associate_v2" "k8s_node3_floating_ip" {
  floating_ip = "${openstack_networking_floatingip_v2.k8s_node3_floating_ip.address}"
  instance_id = "${openstack_compute_instance_v2.k8s_node3_instance.id}"
  fixed_ip    = "${openstack_compute_instance_v2.k8s_node3_instance.network.0.fixed_ip_v4}"
}
