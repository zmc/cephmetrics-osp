#!/usr/bin/env bash
set -x

openstack server delete cephmetrics

openstack router remove subnet cm_pub cm_pub
openstack router delete cm_pub
openstack subnet delete cm_pub
openstack network delete cm_pub

openstack router remove subnet cm_priv cm_priv
openstack router delete cm_priv
openstack subnet delete cm_priv
openstack network delete cm_priv
