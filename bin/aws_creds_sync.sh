#!/bin/bash
# (sourced from ~/.zshrc — uses zsh parameter expansions)

# AWS auth via aws-okta-processor + credential_process (auto-refreshing), with a
# systematic alias scheme over every account/role the Okta app grants.
#
# Model: ~/.aws/config defines one profile per account/role, each calling
# aws-okta-processor as a `credential_process`. The AWS SDK/CLI invokes it on
# demand and RE-INVOKES it automatically when the session expires — no static
# credentials file, no environment variables.
#
# Alias scheme (what you type):  <service>[-<accounttype>][-<role>]
#   * The default account type and default role are implied and never typed
#     (e.g. `web`, `web-ops`, `data-prod-ops`).
#   * The vocabulary (account types, roles, defaults, friendly service aliases)
#     is supplied ENTIRELY via environment variables — see ~/.config/secrets.env.
#     This script carries no organization-specific values.
#
# Required env (from ~/.config/secrets.env, sourced before this file):
#   AWS_OKTA_ORG / AWS_OKTA_USER / AWS_OKTA_APP   Okta identity.
#   AWSPROF_ACCOUNTTYPES   account-type tokens, priority order ([1] = default).
#   AWSPROF_ROLES          role tokens, priority order ([1] = default).
#   AWSPROF_SERVICE_ALIASES  "from=to ..." friendly service renames (optional).
#   AWSPROF_DEFAULT_TARGET   default alias for `aws-refresh` with no arg (optional).
#
# Source of truth for the alias table: $AWS_OKTA_ROLES_RAW (a get-roles dump) →
# gen-aws-profiles.py → $AWS_OKTA_ROLES_TSV. Rebuild via `aws-roles-refresh`.
#
# Commands: aws-refresh [target|--list [filter]] | aws-clear | aws-info |
#           awsr <cmd> | aws-config-regenerate | aws-roles-refresh |
#           aws-refresh-static [target]   (fallback static-file writer)

AWS_CONFIG_DIR="$HOME/.aws"
AWS_CONFIG_FILE="$AWS_CONFIG_DIR/config"
AWS_CREDS_FILE="$AWS_CONFIG_DIR/credentials"
AWS_ROLES_RAW="${AWS_OKTA_ROLES_RAW:-$AWS_CONFIG_DIR/aws-okta-roles.raw.txt}"
AWS_ROLES_TSV="${AWS_OKTA_ROLES_TSV:-$AWS_CONFIG_DIR/aws-okta-roles.tsv}"

AWS_OKTA_BIN="$HOME/.local/bin/aws-okta-processor"
AWS_OKTA_GEN="$HOME/.local/bin/gen-aws-profiles.py"
# Wrapper that injects the Okta password from the macOS Keychain so refreshes
# need only a YubiKey touch. Falls back to the raw binary if the wrapper is
# absent (so this stays portable). See ~/.local/bin/aws-okta-auth.
AWS_OKTA_AUTH="$HOME/.local/bin/aws-okta-auth"
[ -x "$AWS_OKTA_AUTH" ] || AWS_OKTA_AUTH="$AWS_OKTA_BIN"

# Okta identity (from the environment; no defaults baked in). If unset, AWS auth
# wiring is skipped so the script is safe to run anywhere.
AWS_OKTA_ORG="${AWS_OKTA_ORG:-}"
AWS_OKTA_USER="${AWS_OKTA_USER:-}"
AWS_OKTA_APP="${AWS_OKTA_APP:-}"
AWS_OKTA_FACTOR="${AWS_OKTA_FACTOR:-token:hardware:yubico}"
# Role max is governed by IAM; the Okta SAML assertion may cap it lower. We
# request 4h so we benefit automatically if the assertion limit is ever raised.
AWS_OKTA_DURATION="${AWS_OKTA_DURATION:-14400}"

if [[ -z "$AWS_OKTA_ORG" || -z "$AWS_OKTA_USER" || -z "$AWS_OKTA_APP" ]]; then
    echo "ℹ AWS okta identity not set (AWS_OKTA_ORG/USER/APP) — add them to ~/.config/secrets.env to enable AWS auth."
    return 0 2>/dev/null || exit 0
fi

mkdir -p "$AWS_CONFIG_DIR"

# ── Naming vocabulary (from the environment) ──────────────────────────────────
_AWS_ATYPES=( ${=AWSPROF_ACCOUNTTYPES} )   # priority order; [1] = implied default
_AWS_ROLES_LIST=( ${=AWSPROF_ROLES} )      # priority order; [1] = implied default
_AWS_DEF_ATYPE="${AWSPROF_DEFAULT_ACCOUNTTYPE:-${_AWS_ATYPES[1]}}"
_AWS_DEF_ROLE="${AWSPROF_DEFAULT_ROLE:-${_AWS_ROLES_LIST[1]}}"
typeset -gA _AWS_SVC_ALIAS
for _kv in ${=AWSPROF_SERVICE_ALIASES}; do _AWS_SVC_ALIAS[${_kv%%=*}]="${_kv#*=}"; done
unset _kv

AWS_DEFAULT_TARGET="${AWS_DEFAULT_TARGET:-${AWSPROF_DEFAULT_TARGET:-}}"

# ── Role table (loaded from the TSV) ──────────────────────────────────────────
typeset -gA _AWS_ARN _AWS_ACCT _AWS_SVC _AWS_ATYPE _AWS_ROLE

_aws_load_roles() {
    _AWS_ARN=(); _AWS_ACCT=(); _AWS_SVC=(); _AWS_ATYPE=(); _AWS_ROLE=()
    [ -f "$AWS_ROLES_TSV" ] || return 1
    local name acct arn aname svc atype role
    while IFS=$'\t' read -r name acct arn aname svc atype role; do
        [ "$name" = "profile_name" ] && continue
        [ -z "$name" ] && continue
        _AWS_ARN[$name]="$arn"; _AWS_ACCT[$name]="$acct"; _AWS_SVC[$name]="$svc"
        _AWS_ATYPE[$name]="$atype"; _AWS_ROLE[$name]="$role"
    done < "$AWS_ROLES_TSV"
}

# Priority of a token = its 1-based position in the configured list (zero-padded
# so string comparison of concatenated keys works). Lower = preferred.
_aws_role_prio()  { local i=1 x; for x in "${_AWS_ROLES_LIST[@]}"; do [[ "$x" == "$1" ]] && { printf '%02d' $i; return }; ((i++)); done; printf '99' }
_aws_atype_prio() { local i=1 x; for x in "${_AWS_ATYPES[@]}";     do [[ "$x" == "$1" ]] && { printf '%02d' $i; return }; ((i++)); done; printf '99' }

# Resolve user input → a canonical profile alias (echoed). Non-zero if no match.
# Handles: case, friendly service aliases, the implied default accounttype/role,
# and <service>[-<accounttype>] shorthands.
_aws_resolve_target() {
    local in="${1:l}"
    local from
    for from in ${(k)_AWS_SVC_ALIAS}; do
        if [[ "$in" == "$from" || "$in" == "$from-"* ]]; then
            in="${_AWS_SVC_ALIAS[$from]}${in#$from}"; break
        fi
    done
    [[ -n "$_AWS_DEF_ATYPE" ]] && in="${in/-$_AWS_DEF_ATYPE/}"
    [[ -n "$_AWS_DEF_ROLE"  ]] && in="${in%-$_AWS_DEF_ROLE}"
    [[ -z "$in" ]] && return 1
    if [[ -n "${_AWS_ARN[$in]}" ]]; then print -r -- "$in"; return 0; fi

    local svc="${in%%-*}"
    local rest="${in#$svc}"; rest="${rest#-}"
    local best="" best_key="" name key
    if [[ -z "$rest" ]]; then
        for name in ${(k)_AWS_ARN}; do
            [[ "${_AWS_SVC[$name]}" == "$svc" ]] || continue
            key="$(_aws_atype_prio "${_AWS_ATYPE[$name]}")$(_aws_role_prio "${_AWS_ROLE[$name]}")"
            [[ -z "$best" || "$key" < "$best_key" ]] && { best="$name"; best_key="$key"; }
        done
    elif (( ${_AWS_ATYPES[(Ie)$rest]} )); then
        for name in ${(k)_AWS_ARN}; do
            [[ "${_AWS_SVC[$name]}" == "$svc" && "${_AWS_ATYPE[$name]}" == "$rest" ]] || continue
            key="$(_aws_role_prio "${_AWS_ROLE[$name]}")"
            [[ -z "$best" || "$key" < "$best_key" ]] && { best="$name"; best_key="$key"; }
        done
    fi
    [[ -n "$best" ]] && { print -r -- "$best"; return 0; }
    return 1
}

_aws_credprocess_line() {
    local role_arn="$1" key="$2"
    echo "$AWS_OKTA_AUTH authenticate -o $AWS_OKTA_ORG -u $AWS_OKTA_USER --application $AWS_OKTA_APP --factor $AWS_OKTA_FACTOR --role $role_arn --duration $AWS_OKTA_DURATION --key $key --silent"
}

_aws_emit_profile() {
    local header="$1" role_arn="$2" key="$3"
    cat <<EOF
[$header]
credential_process = $(_aws_credprocess_line "$role_arn" "$key")
s3 =
    addressing_style = path

EOF
}

# Regenerate ~/.aws/config from the TSV. One [profile <alias>] per role.
aws-config-regenerate() {
    [ -f "$AWS_ROLES_TSV" ] || { echo "✗ $AWS_ROLES_TSV missing — run aws-roles-refresh"; return 1; }
    local default_resolved=""
    if [ -n "$AWS_DEFAULT_TARGET" ]; then
        default_resolved="$(_aws_resolve_target "$AWS_DEFAULT_TARGET")" || {
            echo "✗ AWS_DEFAULT_TARGET '$AWS_DEFAULT_TARGET' did not resolve"; return 1; }
    fi
    {
        cat <<EOF
# AWS config — per-account profiles using aws-okta-processor as a
# credential_process. The SDK/CLI invokes it on demand and AUTO-REFRESHES on
# expiry (no static credentials file, no env vars).
#
# GENERATED by \`aws-config-regenerate\` from the role TSV — do not edit by hand.
# Switch with \`aws-refresh <alias>\` or \`aws --profile <alias>\`.
# Alias scheme: <service>[-<accounttype>][-<role>] (default accounttype + role implied).

EOF
        [ -n "$default_resolved" ] && _aws_emit_profile "default" "${_AWS_ARN[$default_resolved]}" "$default_resolved"
        local name arn
        awk -F'\t' 'NR>1 && $1!="" {print $1"\t"$3}' "$AWS_ROLES_TSV" | sort | \
        while IFS=$'\t' read -r name arn; do
            _aws_emit_profile "profile $name" "$arn" "$name"
        done
    } > "$AWS_CONFIG_FILE"
    chmod 600 "$AWS_CONFIG_FILE"
    echo "✓ Wrote $AWS_CONFIG_FILE ($(grep -c '^\[profile ' "$AWS_CONFIG_FILE") profiles${default_resolved:+ + [default]=$default_resolved})"
}

# Rebuild the TSV + config from the saved role inventory. To pick up NEW roles,
# re-run the role menu and replace $AWS_ROLES_RAW with a fresh dump:
#   aws-okta-processor authenticate -o "$AWS_OKTA_ORG" -u "$AWS_OKTA_USER" \
#     --application "$AWS_OKTA_APP" --factor "$AWS_OKTA_FACTOR"   # shows the menu
aws-roles-refresh() {
    [ -f "$AWS_ROLES_RAW" ] || { echo "✗ $AWS_ROLES_RAW missing"; return 1; }
    [ -x "$AWS_OKTA_GEN" ] || { echo "✗ $AWS_OKTA_GEN missing"; return 1; }
    python3 "$AWS_OKTA_GEN" "$AWS_ROLES_RAW" "$AWS_ROLES_TSV" || return 1
    _aws_load_roles
    aws-config-regenerate
}

aws_clear_env() {
    local aws_vars=(AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_SECURITY_TOKEN AWS_CREDENTIAL_EXPIRATION)
    local cleared=0 var
    for var in "${aws_vars[@]}"; do
        if [ -n "${(P)var}" ]; then unset "$var"; ((cleared++)); fi
    done
    [ $cleared -gt 0 ] && echo "✓ Cleared $cleared AWS environment variable(s)"
}

_aws_list_targets() {
    local filter="${1:l}"
    echo "Aliases (the default account type and role are implied):"
    awk -F'\t' 'NR>1 && $1!=""{print $1"\t"$2"\t"$3}' "$AWS_ROLES_TSV" | sort | \
    while IFS=$'\t' read -r name acct arn; do
        [[ -n "$filter" && "${name:l}" != *"$filter"* ]] && continue
        printf "  %-34s %s  %s\n" "$name" "$acct" "${arn##*/}"
    done
    echo "Default: ${AWS_DEFAULT_TARGET:-<none>}   (override: export AWS_DEFAULT_TARGET=<alias>)"
}

# Select an account (set AWS_PROFILE) and warm it so any YubiKey touch happens
# now rather than mid-command. credential_process handles refresh thereafter.
aws-refresh() {
    local target="${1:-$AWS_DEFAULT_TARGET}"
    if [[ "$target" == "--list" || "$target" == "-l" ]]; then _aws_list_targets "$2"; return 0; fi
    [ -z "$target" ] && { echo "No target given and AWS_DEFAULT_TARGET unset. Try: aws-refresh --list"; return 1; }

    local resolved
    resolved="$(_aws_resolve_target "$target")" || {
        echo "Unknown target '$target'. Try: aws-refresh --list [filter]"; return 1; }

    if ! grep -q "^\[profile $resolved\]" "$AWS_CONFIG_FILE" 2>/dev/null; then
        echo "Profile [$resolved] not in config; regenerating…"
        aws-config-regenerate || return 1
    fi

    aws_clear_env
    export AWS_PROFILE="$resolved"
    echo "✓ AWS_PROFILE=$resolved  (${_AWS_ARN[$resolved]##*/} @ ${_AWS_ACCT[$resolved]})"
    echo "Warming credentials (touch YubiKey if prompted)…"
    local identity
    if identity=$(aws sts get-caller-identity 2>/dev/null); then
        echo "✓ Active: $(echo "$identity" | jq -r '.Arn' | sed 's#.*/##') @ $(echo "$identity" | jq -r '.Account')"
    else
        echo "✗ Could not obtain credentials for '$resolved' (re-run, or 'aws-info')."
        return 1
    fi
}

awsr() { aws "$@"; }

aws-info() {
    echo "=== AWS Credential Status ==="
    echo "Active profile: ${AWS_PROFILE:-default}"
    if [ -n "$AWS_ACCESS_KEY_ID" ] || [ -n "$AWS_SECRET_ACCESS_KEY" ]; then
        echo "⚠️  AWS_* env vars are set — they OVERRIDE the credential_process profile."
        echo "    Run 'aws-clear' to remove them."
    fi
    local expires
    local -a _caches
    _caches=( "$AWS_CONFIG_DIR"/boto/cache/*.json(Nom) "$AWS_CONFIG_DIR"/cli/cache/*.json(Nom) )
    if [ -n "${_caches[1]}" ]; then
        expires=$(jq -r '(.Credentials.Expiration // .Expiration // empty)' "${_caches[1]}" 2>/dev/null)
        [ -n "$expires" ] && echo "Cached expiry (newest): $expires"
    fi
    echo "Credential Test:"
    local identity
    if identity=$(aws sts get-caller-identity 2>/dev/null); then
        echo "  ✓ Valid — Account: $(echo "$identity" | jq -r '.Account')  User: $(echo "$identity" | jq -r '.Arn' | sed 's#.*/##')"
    else
        echo "  ✗ No valid credentials — run 'aws-refresh [target]'"
    fi
}

aws-clear() {
    aws_clear_env
    unset AWS_PROFILE
    echo "✓ Cleared AWS_PROFILE and env vars (will use [default] profile from ~/.aws/config)"
}

# ── FALLBACK ──────────────────────────────────────────────────────────────────
# Write the OLD static ~/.aws/credentials file for a target. Use only if a tool
# can't handle credential_process. A [default] block here OVERRIDES every
# credential_process profile, disabling auto-refresh until the file is removed.
aws-refresh-static() {
    local target="${1:-$AWS_DEFAULT_TARGET}" resolved role_arn
    resolved="$(_aws_resolve_target "$target")" || {
        echo "Unknown target '$target'. Try: aws-refresh --list"; return 1; }
    role_arn="${_AWS_ARN[$resolved]}"

    echo "Fetching STATIC credentials for: $resolved ($role_arn)"
    aws_clear_env
    local creds
    creds=$("$AWS_OKTA_AUTH" authenticate -o "$AWS_OKTA_ORG" -u "$AWS_OKTA_USER" \
        --application "$AWS_OKTA_APP" --factor "$AWS_OKTA_FACTOR" \
        --duration "$AWS_OKTA_DURATION" --no-aws-cache --role "$role_arn") \
        || { echo "Failed to fetch credentials"; return 1; }

    local access_key secret_key session_token expiration
    access_key=$(echo "$creds" | jq -r '.AccessKeyId // empty')
    secret_key=$(echo "$creds" | jq -r '.SecretAccessKey // empty')
    session_token=$(echo "$creds" | jq -r '.SessionToken // empty')
    expiration=$(echo "$creds" | jq -r '.Expiration // empty')
    if [ -z "$access_key" ] || [ -z "$secret_key" ]; then
        echo "✗ No credentials in response — bad role or access denied. File unchanged."
        return 1
    fi

    cat > "$AWS_CREDS_FILE" <<EOF
[default]
aws_access_key_id = $access_key
aws_secret_access_key = $secret_key
aws_session_token = $session_token
EOF
    [ -n "$expiration" ] && echo "# Expires: $expiration" >> "$AWS_CREDS_FILE"
    chmod 600 "$AWS_CREDS_FILE"
    echo "✓ Static credentials written to $AWS_CREDS_FILE${expiration:+  (Expires: $expiration)}"
    echo "⚠️  This [default] block OVERRIDES credential_process auto-refresh."
    echo "    Remove $AWS_CREDS_FILE to re-enable auto-refresh."
}

# ── init ──────────────────────────────────────────────────────────────────────
_aws_load_roles
if [ -n "$AWS_ACCESS_KEY_ID" ] || [ -n "$AWS_SECRET_ACCESS_KEY" ]; then
    echo "⚠️  WARNING: AWS credentials detected in environment variables!"
    echo "   These OVERRIDE the credential_process profiles in ~/.aws/config."
    echo "   Run 'aws-clear' to remove them."
    echo ""
fi

echo "AWS auth loaded (credential_process / auto-refresh, ${#_AWS_ARN} aliases). Commands:"
echo "  aws-refresh [target] - Select account + warm (default: ${AWS_DEFAULT_TARGET:-<none>}; '--list [filter]')"
echo "  aws-clear            - Unset AWS_PROFILE + env vars"
echo "  aws-info             - Show active profile, identity, cached expiry"
echo "  awsr <cmd>           - Run aws under current profile"
