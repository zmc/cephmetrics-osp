#!/usr/bin/env python
import argparse
import yaml

GROUP_MAP = dict(
  Controller=['mons', 'mgrs'],
  CephStorage=['osds'],
)


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "file",
        nargs=1,
    )
    return parser.parse_args()


def get_inventory(orig_obj, group_map):
    new_obj = dict()
    for orig_group_name, new_group_names in group_map.items():
        orig_group = orig_obj.get(orig_group_name)
        if orig_group is None:
            continue
        ips = dict()
        for child_name in orig_group['children'].keys():
            ips[child_name] = orig_obj[child_name]['vars']['ctlplane_ip']
            for new_group_name in new_group_names:
                if new_group_name not in new_obj:
                    new_obj[new_group_name] = dict()
                new_obj[new_group_name][child_name] = dict(
                    ansible_host=ips[child_name],
                    ansible_ssh_user='heat-admin',
                )
    return new_obj


def format_inventory(inventory_obj):
    lines = []
    for group_name, group in inventory_obj.items():
        lines.append('[%s]' % group_name)
        for child_name in sorted(group.keys()):
            s = ' '.join(
                [child_name] +
                ['%s=%s' % kv for kv in group[child_name].items()]
            )
            lines.append(s)
    return '\n'.join(lines)


if __name__ == "__main__":
    args = parse_args()

    with open(args.file[0]) as f:
        orig_obj = yaml.safe_load(f)

    inv = get_inventory(orig_obj, GROUP_MAP)
    print format_inventory(inv)
