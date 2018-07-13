#!/bin/bash

TRIPLEO_INVENTORY=tripleo-inventory.yaml
CONVERT_PLAYBOOK=convert-inventory.yaml

tripleo-ansible-inventory --static-yaml-inventory $TRIPLEO_INVENTORY
ansible --ssh-extra-args "-o StrictHostKeyChecking=no" -i $TRIPLEO_INVENTORY all -m ping
ansible-playbook -i ./$TRIPLEO_INVENTORY $CONVERT_PLAYBOOK
