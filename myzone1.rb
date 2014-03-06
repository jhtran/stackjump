#
# Cookbook Name:: openstack-base
# Recipe:: myzone1
#
# Copyright 2013, AT&T Services, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

node.override["zone"] = "myzone1"
node.override["region"] = "andromeda"

include_recipe "openstack-base::zone"
include_recipe "openstack-base::default"

env = node.chef_environment
include_recipe "openstack-base::#{env}"

node.override["openstack"]["block-storage"]["max_gigabytes"] = "70000"
node.override["openstack"]["block-storage"]["netapp"]["netapp_server_login"] = "openstk"
node.override["openstack"]["block-storage"]["volume"]["driver"] = "cinder.volume.drivers.netapp.nfs.NetAppDirect7modeNfsDriver"

node.override["openstack"]["compute"]["network"]["floating"]["public_network_name"] = "public"

node.override["swift"]["disk_enum_expr"] = "Hash[('e'..'z').to_a.collect{|x| [ \"sd\#{x}\", {} ]} + ('aa'..'az').to_a.collect{|x| [ \"sd\#{x}\", {} ]}]"

node.override["openstack"]["compute"]["config"]["quota_instances"] = 0
