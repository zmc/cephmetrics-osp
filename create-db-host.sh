#!/usr/bin/env bash
set -ex
curl -C - -O http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2.xz
xz -d CentOS-7-x86_64-GenericCloud.qcow2.xz || true
##openstack volume create "cephmetrics" --size 20
openstack image create "centos_7" --file ./CentOS-7-x86_64-GenericCloud.qcow2 --disk-format qcow2 --container-format bare --public
##openstack server create "cephmetrics" --image centos_7 --volume cephmetrics --wait
openstack flavor create --ram 4096 --ephemeral 40 --vcpus 2 --public m1.medium
# TODO: needs keypair: openstack keypair create demokp > ~/demokp.pem
# TODO: needs network
# TODO: from John: openstack server create --flavor m1.medium --image rhel7 --key-name demokp inst1 --nic net-id=$netid
openstack server create "cephmetrics" --image centos_7 --flavor m1.medium --wait
