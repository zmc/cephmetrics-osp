#!/usr/bin/env python
import argparse
import json
import yaml


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "file",
        nargs=1,
    )
    parser.add_argument(
        "-i", "--input-format",
        choices=["tripleo", "ceph-ansible"],
        default="tripleo",
    )
    parser.add_argument(
        "-f", "--format",
        choices=["hosts", "hosts_yaml", "raw", "yaml"],
        default="yaml",
    )
    return parser.parse_args()


def load_file(path):
    ext = None
    if '.' in path:
        ext = path.split('.')[-1]
    with open(path) as f:
        contents = f.read()
    if ext in ('yaml', 'yml'):
        return yaml.safe_load(contents)
    elif ext in ('json'):
        return json.loads(contents)
    elif ext is None:
        raise NotImplementedError


def simplify_tripleo_inventory(orig_obj):
    group_map = dict(
      Controller=['mons', 'mgrs'],
      CephStorage=['osds'],
      Compute=['iscsis'],
    )
    new_obj = dict(
        ungrouped=dict(),
    )
    for orig_group_name, new_group_names in group_map.items():
        orig_group = orig_obj.get(orig_group_name)
        if orig_group is None:
            continue
        ips = dict()
        for child_name in orig_group['children'].keys():
            ips[child_name] = orig_obj[child_name]['vars']['ctlplane_ip']
            new_obj['ungrouped'][child_name] = dict(
                ansible_host=ips[child_name],
                ansible_ssh_user='heat-admin',
            )
            for new_group_name in new_group_names:
                new_obj.setdefault(new_group_name, dict()).setdefault(
                    'hosts', dict())[child_name] = dict()
    return new_obj


def format_hosts_dict(inventory_obj):
    hosts_obj = dict()
    for group_name, group in inventory_obj.items():
        for host_name, host in group.items():
            if 'ansible_host' in host:
                hosts_obj[host_name] = host['ansible_host']
    return hosts_obj


def format_hosts(inventory_obj):
    hosts_obj = format_hosts_dict(inventory_obj)
    return reduce(
        lambda x, y: "\n".join([x, y]),
        map(
            lambda x: " ".join(x[::-1]),
            hosts_obj.items(),
        ),
    )


def format_hosts_yaml(inventory_obj):
    hosts_obj = format_hosts_dict(inventory_obj)
    return yaml.safe_dump(
        hosts_obj,
        default_flow_style=False,
    )


if __name__ == "__main__":
    args = parse_args()

    orig_obj = load_file(args.file[0])

    if args.input_format == "tripleo":
        inv = simplify_tripleo_inventory(orig_obj)
    elif args.input_format == "ceph-ansible":
        inv = orig_obj

    if args.format == "yaml":
        print yaml.safe_dump(inv, default_flow_style=False)
    elif args.format == "hosts":
        print format_hosts(inv)
    elif args.format == "hosts_yaml":
        print format_hosts_yaml(inv)
    elif args.format == "raw":
        print inv
