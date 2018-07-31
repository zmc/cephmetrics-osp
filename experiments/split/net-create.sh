#!/usr/bin/env bash
set -ex
DEMO_CIDR="172.16.66.0/24"
openstack network create cm_priv
openstack subnet create --network cm_priv --subnet-range ${DEMO_CIDR} cm_priv
priv_sub_id=$(openstack subnet list | awk "/cm_priv/ {print \$2}")
openstack router create cm_priv
openstack router add subnet cm_priv $priv_sub_id
priv_net_id=$(openstack network list | awk "/cm_priv/ { print \$2 }")

openstack network create cm_pub --provider-network-type flat --provider-physical-network datacentre --external --share
pub_net_id=$(openstack network list | awk "/cm_pub/ { print \$2 }")
openstack subnet create cm_pub --network cm_pub --subnet-range 192.168.4.0/23 --allocation-pool start=192.168.4.2,end=192.168.5.252

#openstack server create "cephmetrics" --image centos_7 --flavor m1.medium --key-name cephmetrics --nic net-id=${priv_net_id} --nic net-id=${pub_net_id} --wait
openstack server create "cephmetrics" --image centos_7 --flavor m1.medium --key-name cephmetrics --network cm_priv --network cm_pub --wait
