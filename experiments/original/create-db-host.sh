#!/usr/bin/env bash
if [ $OS_CLOUDNAME == "undercloud" ]
then
  echo "You need to source ~/overcloudrc" >&2
  exit 1
fi
set -ex
openstack volume create "cephmetrics" --size 20
#curl -C - -O http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2.xz
#xz -d CentOS-7-x86_64-GenericCloud.qcow2.xz || true
openstack image create "centos_7" --file ./CentOS-7-x86_64-GenericCloud.qcow2 --disk-format qcow2 --container-format bare --public
##openstack server create "cephmetrics" --image centos_7 --volume cephmetrics --wait
openstack flavor create --ram 4096 --ephemeral 40 --vcpus 2 --public m1.medium
openstack keypair create cephmetrics > ~/cephmetrics.pem
# TODO: needs network
# net-create public_network --provider:network_type flat --provider:physical_network datacentre --router:external --shared
#openstack network create "cephmetrics" --provider-network-type flat --provider-physical-network datacentre --external --share
#net_id=$(openstack network list | awk "/cephmetrics/ { print \$2 }")

DEMO_CIDR="172.16.66.0/24"
openstack network create cephmetrics_private
openstack subnet create --network cephmetrics_private --subnet-range ${DEMO_CIDR} cephmetrics_private
subid=$(openstack subnet list | awk "/cephmetrics_private/ {print \$2}")
openstack router create cephmetrics
openstack router add subnet cephmetrics $subid
net_id=$(openstack network list | awk "/cephmetrics_private/ { print \$2 }")


# http://blog.johnlikesopenstack.com/2016/05/plumbing-into-tenant-network-from.html
#neutron net-create testing_network --provider:segmentation_id 4060 --provider:network_type vlan --provider:physical_network tenant
openstack network create cephmetrics --provider-segment 4060 --provider-network-type flat --provider-physical-network tenant
#neutron subnet-create --name testing_subnet --allocation-pool start=192.168.4.2,end=192.168.5.252 testing_network 192.168.4.0/23
openstack subnet create cephmetrics --network cephmetrics --subnet-range 192.168.4.0/23 --allocation-pool start=192.168.4.2,end=192.168.5.252


# TODO: from John: openstack server create --flavor m1.medium --image rhel7 --key-name demokp inst1 --nic net-id=$netid
openstack server create "cephmetrics" --image centos_7 --flavor m1.medium --key-name cephmetrics --nic net-id=${net_id} --wait
