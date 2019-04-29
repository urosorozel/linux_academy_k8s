data "openstack_compute_flavor_v2" "openstack_flavor" {
  vcpus = 4
  ram   = 8192
}

data "openstack_images_image_v2" "openstack_image" {
  name = "CentOS-7-x86_64"
  most_recent = true
}

data "openstack_networking_network_v2" "openstack_external_network" {
  name = "${var.openstack_external_network}"
}
