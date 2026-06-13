#!/usr/bin/env python3
"""
Add NS records to a Route53 hosted zone in Account B.
Reads the NS records from the 'record' file created by get_ns_records.py.

Usage:
    AWS_PROFILE=<account-b-profile> python3 add_ns_record.py
"""

import json
import os
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
RECORD_FILE = os.path.join(SCRIPT_DIR, "record")


def run_aws(args):
    result = subprocess.run(
        ["aws"] + args,
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print("AWS CLI error:", file=sys.stderr)
        print(result.stderr, file=sys.stderr)
        sys.exit(1)
    return result.stdout.strip()


def get_hosted_zone_id(zone_name):
    # Route53 stores zone names with a trailing dot
    search_name = zone_name.rstrip(".") + "."
    output = run_aws([
        "route53", "list-hosted-zones",
        "--query", f"HostedZones[?Name=='{search_name}'].Id",
        "--output", "text",
    ])
    if not output:
        print(f"No hosted zone found with name: {zone_name}", file=sys.stderr)
        sys.exit(1)
    # ID comes back as /hostedzone/XXXXXXXXXXXX
    return output.strip().split("/")[-1]


def load_records():
    if not os.path.exists(RECORD_FILE):
        print(f"Record file not found: {RECORD_FILE}", file=sys.stderr)
        print("Run get_ns_records.py first.", file=sys.stderr)
        sys.exit(1)
    with open(RECORD_FILE) as f:
        return json.load(f)


def upsert_ns_record(hosted_zone_id, record_name, name_servers, ttl):
    change_batch = {
        "Changes": [
            {
                "Action": "UPSERT",
                "ResourceRecordSet": {
                    "Name": record_name,
                    "Type": "NS",
                    "TTL": ttl,
                    "ResourceRecords": [{"Value": ns} for ns in name_servers],
                },
            }
        ]
    }
    output = run_aws([
        "route53", "change-resource-record-sets",
        "--hosted-zone-id", hosted_zone_id,
        "--change-batch", json.dumps(change_batch),
    ])
    return json.loads(output)


def select_zone(records):
    if len(records) == 1:
        return records[0]

    print("Multiple zones found in record file:")
    for i, zone in enumerate(records):
        print(f"  [{i}] {zone['name']}")
    idx = input("\nSelect zone index: ").strip()
    try:
        return records[int(idx)]
    except (ValueError, IndexError):
        print("Invalid selection.", file=sys.stderr)
        sys.exit(1)


def main():
    records = load_records()

    print("NS records loaded from record file:")
    for zone in records:
        print(f"  {zone['name']}")
        for ns in zone["name_servers"]:
            print(f"    NS  {ns}")
    print()

    selected = select_zone(records)

    zone_name = input("Enter the parent hosted zone name (e.g., rodentskie.com): ").strip()
    if not zone_name:
        print("Hosted zone name is required.", file=sys.stderr)
        sys.exit(1)

    print(f"\nLooking up hosted zone ID for: {zone_name}")
    zone_id = get_hosted_zone_id(zone_name)
    print(f"Found hosted zone ID: {zone_id}")

    ttl_input = input("TTL in seconds [default: 172800]: ").strip()
    ttl = int(ttl_input) if ttl_input else 172800

    print(f"\nAbout to UPSERT NS record:")
    print(f"  Parent zone : {zone_name} ({zone_id})")
    print(f"  Record name : {selected['name']}")
    print(f"  NS values   : {', '.join(selected['name_servers'])}")
    print(f"  TTL         : {ttl}")

    confirm = input("\nProceed? [y/N]: ").strip().lower()
    if confirm != "y":
        print("Aborted.")
        sys.exit(0)

    result = upsert_ns_record(zone_id, selected["name"], selected["name_servers"], ttl)
    info = result.get("ChangeInfo", {})
    print(f"\nDone. Change ID: {info.get('Id', '')}  Status: {info.get('Status', '')}")


if __name__ == "__main__":
    main()
