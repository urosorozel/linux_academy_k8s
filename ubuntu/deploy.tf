# Master node(s):
#TCP     6443*       Kubernetes API Server
#TCP     2379-2380   etcd server client API
#TCP     10250       Kubelet API
#TCP     10251       kube-scheduler
#TCP     10252       kube-controller-manager
#TCP     10255       Read-Only Kubelet API
#Worker nodes (minions):
#
#TCP     10250       Kubelet API
#TCP     10255       Read-Only Kubelet API
#TCP     30000-32767 NodePort Services

terraform {
  required_version = ">= 0.11.0"
}

resource "openstack_compute_flavor_v2" "k8s-flavor" {
  name  = "medium-noswap"
  ram   = "8192"
  vcpus = "4"
  disk  = "60"
  is_public = "true"

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

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_2" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 6443
  port_range_max    = 6443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.secgroup_1.id}"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_3" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 10250
  port_range_max    = 10255
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.secgroup_1.id}"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_4" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 30000
  port_range_max    = 32767
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.secgroup_1.id}"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_5" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 2379
  port_range_max    = 2380
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.secgroup_1.id}"
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_6" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.secgroup_1.id}"
}

# flannel
resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_7" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 8472
  port_range_max    = 8472
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${openstack_networking_secgroup_v2.secgroup_1.id}"
}

# Masters
resource "openstack_networking_floatingip_v2" "k8s_master_floating_ip" {
  pool = "${var.openstack_floating_ip_pool}"
  count = "${var.master_node_count}"
}

resource "openstack_compute_instance_v2" "k8s_master_instance" {
  name            = "k8s-master${count.index}"
  image_id        = "${data.openstack_images_image_v2.openstack_image.id}"
  flavor_id       = "${openstack_compute_flavor_v2.k8s-flavor.id}"
  key_pair        = "${var.openstack_keypair}"
  security_groups = ["${openstack_networking_secgroup_v2.secgroup_1.id}"]
  count           = "${var.master_node_count}"

  metadata {
    group = "k8s_masters"
    groups = "k8s_masters,k8s"
  }

  network {
     name = "${openstack_networking_network_v2.management_network.name}"
  }
  depends_on = ["openstack_networking_subnet_v2.management_subnet"]
}

resource "openstack_compute_floatingip_associate_v2" "k8s_master_floating_ip" {
  floating_ip = "${element(openstack_networking_floatingip_v2.k8s_master_floating_ip.*.address, count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.k8s_master_instance.*.id, count.index)}"
  fixed_ip    = "${element(openstack_compute_instance_v2.k8s_master_instance.*.network.0.fixed_ip_v4, count.index)}"
  count = "${var.master_node_count}"
}

# Minions
resource "openstack_networking_floatingip_v2" "k8s_node_floating_ip" {
  pool = "${var.openstack_floating_ip_pool}"
  count = "${var.minion_node_count}"
}

resource "openstack_compute_instance_v2" "k8s_node_instance" {
  name            = "k8s-node${count.index}"
  image_id        = "${data.openstack_images_image_v2.openstack_image.id}"
  flavor_id       = "${openstack_compute_flavor_v2.k8s-flavor.id}"
  key_pair        = "${var.openstack_keypair}"
  security_groups = ["${openstack_networking_secgroup_v2.secgroup_1.id}"]
  #config_drive = true
  count           = "${var.minion_node_count}"

  metadata {
    group = "k8s_nodes"
    groups = "k8s_nodes,k8s"
  }

  network {
      name = "${openstack_networking_network_v2.management_network.name}"
  }
  depends_on = ["openstack_networking_subnet_v2.management_subnet"]
}

resource "openstack_compute_floatingip_associate_v2" "k8s_node_floating_ip" {
  floating_ip = "${element(openstack_networking_floatingip_v2.k8s_node_floating_ip.*.address, count.index)}"
  instance_id = "${element(openstack_compute_instance_v2.k8s_node_instance.*.id, count.index)}"
  fixed_ip    = "${element(openstack_compute_instance_v2.k8s_node_instance.*.network.0.fixed_ip_v4, count.index)}"
  count = "${var.minion_node_count}"
}
