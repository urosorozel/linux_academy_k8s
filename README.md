## Configure terraforms for Openstack

1.  Add below to clouds.yml to return names and not uuid of instances

ansible:
  use_hostnames: True
  expand_hostvars: True

2. Example

```
cat ~/.config/openstack/clouds.yaml
# Ansible managed
clouds:
  default:
    auth:
      auth_url: http://172.29.236.100:5000/v3
      project_name: admin
      tenant_name: admin
      username: admin
      password: 346f8720c8b15402dfc1a281a435571ce51bf4b6ebb7f27c659c1
      user_domain_name: Default
      project_domain_name: Default
    region_name: RegionOne
    interface: internal
    identity_api_version: "3"

ansible:
  use_hostnames: True
  expand_hostvars: True
```
