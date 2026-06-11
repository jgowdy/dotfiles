#!/usr/bin/env python3
"""Generate an AWS profile alias table from an aws-okta-processor get-roles dump.

Parses the menu listing ("Account: <name> (<id>)" / "[ n ] <RoleName>") into a
TSV consumed by aws_creds_sync.sh:
    profile_name  account_id  role_arn  account_name  service  accounttype  role

All naming vocabulary is supplied via the environment, so this file contains NO
organization-specific values:

    AWSPROF_ACCOUNTTYPES   space-separated account-type tokens, in priority order.
                           The first is the implied default and is omitted from
                           profile names (override with AWSPROF_DEFAULT_ACCOUNTTYPE).
    AWSPROF_ROLES          space-separated role tokens, in priority order. The
                           first is the implied default, omitted from names
                           (override with AWSPROF_DEFAULT_ROLE).
    AWSPROF_SERVICE_ALIASES space-separated from=to renames (e.g. "foo=bar").

Alias scheme: <service>[-<accounttype>][-<role>], default accounttype + role omitted.

Usage: gen-aws-profiles.py [RAW_INPUT] [TSV_OUTPUT]
  defaults: $AWS_OKTA_ROLES_RAW or ~/.aws/aws-okta-roles.raw.txt
            $AWS_OKTA_ROLES_TSV or ~/.aws/aws-okta-roles.tsv
"""

import os
import re
import sys


def _env_list(name):
    return os.environ.get(name, "").split()


ACCOUNT_TYPES = _env_list("AWSPROF_ACCOUNTTYPES")
ROLES = _env_list("AWSPROF_ROLES")
DEFAULT_ACCOUNTTYPE = os.environ.get("AWSPROF_DEFAULT_ACCOUNTTYPE") or (
    ACCOUNT_TYPES[0] if ACCOUNT_TYPES else ""
)
DEFAULT_ROLE = os.environ.get("AWSPROF_DEFAULT_ROLE") or (ROLES[0] if ROLES else "")
SERVICE_ALIASES = dict(
    kv.split("=", 1) for kv in _env_list("AWSPROF_SERVICE_ALIASES") if "=" in kv
)

# Match longer tokens first so a multi-word account type beats its prefix
# (e.g. a hyphenated "foo-bar" is matched before the bare "foo").
_ACCT_BY_LEN = sorted(ACCOUNT_TYPES, key=len, reverse=True)
_ROLE_BY_LEN = sorted(ROLES, key=len, reverse=True)

ACCOUNT_RE = re.compile(r"^Account:\s+(\S+)\s+\((\d+)\)\s*$")
ROLE_RE = re.compile(r"^\s*\[\s*\d+\s*\]\s+(\S+)\s*$")


def parse_accounttype(account_name):
    for at in _ACCT_BY_LEN:
        if account_name.endswith("-" + at):
            return at
    return ""


def parse_service(account_name, accounttype):
    base = account_name
    if accounttype:
        base = base[: -(len(accounttype) + 1)]
    return base.split("-")[-1]


def parse_role(role_name):
    low = role_name.lower()
    for tok in _ROLE_BY_LEN:
        if tok in low:
            return tok
    return low.rsplit("-", 1)[-1]  # fallback: trailing token


def profile_name(service, accounttype, role):
    parts = [SERVICE_ALIASES.get(service, service)]
    if accounttype != DEFAULT_ACCOUNTTYPE:
        parts.append(accounttype)
    if role != DEFAULT_ROLE:
        parts.append(role)
    return "-".join(parts)


def main():
    raw_path = sys.argv[1] if len(sys.argv) > 1 else os.environ.get(
        "AWS_OKTA_ROLES_RAW", os.path.expanduser("~/.aws/aws-okta-roles.raw.txt")
    )
    out_path = sys.argv[2] if len(sys.argv) > 2 else os.environ.get(
        "AWS_OKTA_ROLES_TSV", os.path.expanduser("~/.aws/aws-okta-roles.tsv")
    )

    if not ACCOUNT_TYPES or not ROLES:
        sys.stderr.write(
            "✗ AWSPROF_ACCOUNTTYPES and AWSPROF_ROLES must be set "
            "(see ~/.config/secrets.env).\n"
        )
        sys.exit(2)

    rows = []
    account_name = account_id = None
    with open(raw_path) as fh:
        for line in fh:
            m = ACCOUNT_RE.match(line)
            if m:
                account_name, account_id = m.group(1), m.group(2)
                continue
            m = ROLE_RE.match(line)
            if m and account_name:
                role_name = m.group(1)
                accounttype = parse_accounttype(account_name)
                service = parse_service(account_name, accounttype)
                role = parse_role(role_name)
                name = profile_name(service, accounttype, role)
                role_arn = f"arn:aws:iam::{account_id}:role/{role_name}"
                rows.append(
                    (name, account_id, role_arn, account_name,
                     SERVICE_ALIASES.get(service, service), accounttype, role)
                )

    seen = {}
    for r in rows:
        seen.setdefault(r[0], []).append(r)
    collisions = {n: g for n, g in seen.items() if len(g) > 1}
    if collisions:
        sys.stderr.write("✗ ALIAS COLLISIONS DETECTED:\n")
        for name, group in collisions.items():
            sys.stderr.write(f"  {name}:\n")
            for r in group:
                sys.stderr.write(f"    {r[2]}\n")
        sys.exit(2)

    header = ["profile_name", "account_id", "role_arn", "account_name",
              "service", "accounttype", "role"]
    with open(out_path, "w") as fh:
        fh.write("\t".join(header) + "\n")
        for r in sorted(rows):
            fh.write("\t".join(r) + "\n")

    sys.stderr.write(
        f"✓ Wrote {len(rows)} profiles to {out_path} "
        f"({len({r[4] for r in rows})} services, {len({r[1] for r in rows})} accounts)\n"
    )


if __name__ == "__main__":
    main()
