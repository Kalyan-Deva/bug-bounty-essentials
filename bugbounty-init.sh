#!/usr/bin/env bash

set -Eeuo pipefail

# ============================================================
# Bug Bounty Workspace Initializer
#
# Usage:
#   ./bugbounty-init.sh <target-name>
#   ./bugbounty-init.sh <target-name> [base-directory]
#
# Examples:
#   ./bugbounty-init.sh gitlab
#   ./bugbounty-init.sh mergify
#   ./bugbounty-init.sh example ~/research
#
# Default workspace:
#   ~/bugbounty/<target-name>
# ============================================================

TARGET="${1:-}"
BASE_DIR="${2:-${BUGBOUNTY_HOME:-$HOME/bugbounty}}"

usage() {
    cat <<'EOF'
Bug Bounty Workspace Initializer

Usage:
  ./bugbounty-init.sh <target-name> [base-directory]

Examples:
  ./bugbounty-init.sh gitlab
  ./bugbounty-init.sh mergify
  ./bugbounty-init.sh example ~/research

Default location:
  ~/bugbounty/<target-name>

Optional environment variable:
  export BUGBOUNTY_HOME="$HOME/research"
EOF
}

die() {
    printf 'Error: %s\n' "$1" >&2
    exit 1
}

# ------------------------------------------------------------
# Argument validation
# ------------------------------------------------------------

if [[ -z "$TARGET" ]]; then
    usage
    exit 1
fi

if [[ "$TARGET" == "-h" || "$TARGET" == "--help" ]]; then
    usage
    exit 0
fi

# Prevent unsafe directory names.
if [[ ! "$TARGET" =~ ^[A-Za-z0-9._-]+$ ]]; then
    die "Target name may contain only letters, numbers, dots, underscores and hyphens."
fi

WORKSPACE="${BASE_DIR%/}/$TARGET"
TODAY="$(date +%F)"

# ------------------------------------------------------------
# Terminal colors
# ------------------------------------------------------------

if [[ -t 1 ]]; then
    RED=$'\033[0;31m'
    GREEN=$'\033[0;32m'
    YELLOW=$'\033[0;33m'
    BLUE=$'\033[0;34m'
    MAGENTA=$'\033[0;35m'
    CYAN=$'\033[0;36m'
    WHITE=$'\033[0;37m'
    GRAY=$'\033[0;90m'

    BOLD=$'\033[1m'
    BOLD_RED=$'\033[1;31m'
    BOLD_GREEN=$'\033[1;32m'
    BOLD_YELLOW=$'\033[1;33m'
    BOLD_BLUE=$'\033[1;34m'
    BOLD_MAGENTA=$'\033[1;35m'
    BOLD_CYAN=$'\033[1;36m'
    BOLD_WHITE=$'\033[1;37m'

    RESET=$'\033[0m'
else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    MAGENTA=""
    CYAN=""
    WHITE=""
    GRAY=""

    BOLD=""
    BOLD_RED=""
    BOLD_GREEN=""
    BOLD_YELLOW=""
    BOLD_BLUE=""
    BOLD_MAGENTA=""
    BOLD_CYAN=""
    BOLD_WHITE=""

    RESET=""
fi

created_count=0
kept_count=0

# ------------------------------------------------------------
# Helper functions
# ------------------------------------------------------------

make_directory() {
    local path="$1"

    if [[ -d "$path" ]]; then
        ((kept_count += 1))
    else
        mkdir -p "$path"
        ((created_count += 1))
    fi
}

write_if_missing() {
    local path="$1"

    if [[ -e "$path" ]]; then
        printf '%s[KEEP]%s   %s\n' \
            "$YELLOW" "$RESET" "$path"

        ((kept_count += 1))

        # Consume heredoc content without overwriting the file.
        cat >/dev/null
    else
        mkdir -p "$(dirname "$path")"
        cat >"$path"

        printf '%s[CREATE]%s %s\n' \
            "$GREEN" "$RESET" "$path"

        ((created_count += 1))
    fi
}

print_file() {
    local name="$1"
    local description="$2"

    printf '%s%-26s%s %s%s%s\n' \
        "$BOLD_GREEN" \
        "$name" \
        "$RESET" \
        "$GRAY" \
        "$description" \
        "$RESET"
}

print_directory() {
    local name="$1"
    local description="$2"

    printf '\n%s%-26s%s %s%s%s\n' \
        "$BOLD_BLUE" \
        "$name" \
        "$RESET" \
        "$WHITE" \
        "$description" \
        "$RESET"
}

print_child() {
    local name="$1"
    local description="$2"

    printf '  %s%-24s%s %s%s%s\n' \
        "$GREEN" \
        "$name" \
        "$RESET" \
        "$GRAY" \
        "$description" \
        "$RESET"
}

# ------------------------------------------------------------
# Header
# ------------------------------------------------------------

printf '\n%s╔══════════════════════════════════════════════════════════╗%s\n' \
    "$BOLD_CYAN" "$RESET"

printf '%s║          BUG BOUNTY WORKSPACE INITIALIZER               ║%s\n' \
    "$BOLD_CYAN" "$RESET"

printf '%s╚══════════════════════════════════════════════════════════╝%s\n\n' \
    "$BOLD_CYAN" "$RESET"

printf '%sTarget:%s    %s%s%s\n' \
    "$BOLD_WHITE" "$RESET" "$BOLD_GREEN" "$TARGET" "$RESET"

printf '%sWorkspace:%s %s%s%s\n\n' \
    "$BOLD_WHITE" "$RESET" "$BOLD_MAGENTA" "$WORKSPACE" "$RESET"

# ------------------------------------------------------------
# Create essential directories
# ------------------------------------------------------------

directories=(
    "$WORKSPACE/scope"
    "$WORKSPACE/notes"

    "$WORKSPACE/recon/raw"
    "$WORKSPACE/recon/processed"

    "$WORKSPACE/evidence/screenshots"
    "$WORKSPACE/evidence/captures"

    "$WORKSPACE/requests"
    "$WORKSPACE/responses"

    "$WORKSPACE/burp"
    "$WORKSPACE/scripts"
    "$WORKSPACE/reports"
    "$WORKSPACE/secrets"
)

for directory in "${directories[@]}"; do
    make_directory "$directory"
done

# Restrict workspace permissions.
chmod 700 "$WORKSPACE"
chmod 700 "$WORKSPACE/secrets"

# ------------------------------------------------------------
# Main README
# ------------------------------------------------------------

write_if_missing "$WORKSPACE/README.md" <<EOF
# $TARGET Bug Bounty Workspace

Created: $TODAY

## Target information

- Program:
- Platform:
- Policy URL:
- Scope last checked:
- Researcher:
- Testing IP:

## Current status

- [ ] Read the complete program policy
- [ ] Copy all in-scope assets
- [ ] Copy all out-of-scope rules
- [ ] Record account requirements
- [ ] Record identification requirements
- [ ] Configure Burp target scope
- [ ] Create controlled test accounts
- [ ] Capture the normal application baseline
- [ ] Start hypothesis-driven testing

## Safety boundary

Test only assets explicitly authorized by the program.

Use only accounts, organizations, repositories and data that you own or have
explicit permission to access.

Avoid service disruption, destructive actions and privacy violations.

Stop immediately if unexpected private customer data becomes visible.
EOF

# ------------------------------------------------------------
# Git ignore rules
# ------------------------------------------------------------

write_if_missing "$WORKSPACE/.gitignore" <<'EOF'
# Credentials and secrets
secrets/
*.env
.env*
*.key
*.pem
*.token
credentials*
cookies*
session*

# Burp project data
burp/

# Captured HTTP traffic
requests/
responses/

# Evidence
evidence/

# Raw reconnaissance output
recon/raw/

# Logs and temporary files
logs/
*.tmp
*.log
*.zip

# Python
__pycache__/
*.pyc
.venv/
venv/

# Editors and operating systems
.vscode/
.idea/
.DS_Store
Thumbs.db
EOF

# ------------------------------------------------------------
# Scope files
# ------------------------------------------------------------

write_if_missing "$WORKSPACE/scope/scope.md" <<EOF
# $TARGET In-Scope Assets

Policy checked: $TODAY

## Eligible assets

| Asset | Type | Maximum severity | Bounty eligible | Notes |
|---|---|---:|---:|---|
| | | | | |

## Account requirements

- Required researcher email:
- Required HackerOne alias:
- Required HTTP headers:
- Required user-agent:
- Testing-account naming convention:
- Multiple controlled accounts permitted:

## Testing restrictions

- Automated testing:
- Rate limits:
- Production testing:
- Source-code testing:
- Mobile testing:
- API testing:
- Other restrictions:

## Policy URL

-
EOF

write_if_missing "$WORKSPACE/scope/rules.md" <<EOF
# $TARGET Program Rules

Policy checked: $TODAY

## General safety rules

- Test only explicitly authorized assets.
- Use only controlled accounts and synthetic data.
- Avoid privacy violations.
- Avoid destructive actions.
- Avoid service interruption or degradation.
- Do not perform social engineering.
- Do not access another user's private information.
- Submit detailed and reproducible reports.
- Stop testing if unexpected sensitive information appears.

## Program-specific rules

Copy the current rules from the program page:

-
EOF

write_if_missing "$WORKSPACE/scope/out-of-scope.md" <<EOF
# $TARGET Out-of-Scope Items

Policy checked: $TODAY

Copy every exclusion exactly from the program page:

-
EOF

# ------------------------------------------------------------
# Research notes
# ------------------------------------------------------------

write_if_missing "$WORKSPACE/notes/hunting-log.md" <<EOF
# $TARGET Hunting Log

## Session information

- Date:
- Start time:
- End time:
- Policy checked:
- Testing account:
- Source IP:
- VPN used:
- Browser profile:

## Activity log

| Time | Account | Asset or feature | Action | Result | Evidence |
|---|---|---|---|---|---|

## Potential findings

None.

## Unexpected data access

None.

## Session cleanup

- [ ] Temporary access tokens revoked
- [ ] Test API keys revoked
- [ ] Test integrations removed
- [ ] Test webhooks removed
- [ ] Test data deleted or archived
- [ ] Sensitive evidence protected
EOF

write_if_missing "$WORKSPACE/notes/endpoints.md" <<EOF
# $TARGET Endpoint Inventory

| Method | Host | Path | Authentication | Object identifiers | Purpose | Notes |
|---|---|---|---|---|---|---|
EOF

write_if_missing "$WORKSPACE/notes/hypotheses.md" <<EOF
# $TARGET Testing Hypotheses

Record testable security ideas instead of sending random payloads.

| ID | Hypothesis | Preconditions | Expected behavior | Test status | Result |
|---|---|---|---|---|---|
| H-001 | | | | Not started | |
EOF

write_if_missing "$WORKSPACE/notes/accounts.md" <<EOF
# $TARGET Controlled Accounts

Never store passwords, session cookies, access tokens or recovery codes here.

## Account matrix

| Account | Role | Email or alias | Access level | Browser profile | Notes |
|---|---|---|---|---|---|
| Account A | Owner or administrator | | | | |
| Account B | Restricted user or outsider | | | | |

## Controlled resources

| Resource | Account A | Account B | Canary value |
|---|---|---|---|
| | | | |

## Canary values

Use unique harmless text to identify unauthorized data exposure.

Example:

\`\`\`text
TARGET-H1-CANARY-YYYYMMDD-001
\`\`\`
EOF

# ------------------------------------------------------------
# Report template
# ------------------------------------------------------------

write_if_missing "$WORKSPACE/reports/draft.md" <<EOF
# Vulnerability Report Draft — $TARGET

## Title

[Weakness] allows [attacker] to [security impact]

## Summary

Briefly explain the vulnerability and why it matters.

## Asset

- Host:
- Endpoint:
- Feature:
- Account role:
- Environment:

## Prerequisites

1.
2.

## Steps to reproduce

1.
2.
3.

## Expected result

Describe the correct security behavior.

## Actual result

Describe the observed behavior.

## Security impact

Explain what an attacker can read, modify, delete, execute or control.

Avoid theoretical impact. Demonstrate the impact using controlled resources.

## Evidence

- Request file:
- Response file:
- Screenshot:
- Video:
- Canary value:
- Burp request number:

## Suggested remediation

Describe the authorization, validation or isolation control that should be
enforced.

## Cleanup performed

- [ ] Tokens revoked
- [ ] Test resources removed
- [ ] Sensitive evidence redacted
EOF

# ------------------------------------------------------------
# Directory documentation
# ------------------------------------------------------------

write_if_missing "$WORKSPACE/recon/README.md" <<'EOF'
# Reconnaissance

## raw/

Contains original, untouched output produced directly by reconnaissance tools.

Examples:

- Subdomain enumeration
- URL collection
- DNS records
- HTTP probing
- JavaScript file lists

Never modify raw output. Preserve it for comparison and evidence.

## processed/

Contains cleaned, deduplicated, categorized or filtered results.

Only run reconnaissance against assets confirmed to be in scope.
EOF

write_if_missing "$WORKSPACE/evidence/README.md" <<'EOF'
# Evidence

## screenshots/

Contains screenshots supporting a potential vulnerability.

Use descriptive filenames:

H-001-account-b-private-data.png

Redact:

- Passwords
- Tokens
- Session cookies
- Personal information
- Unrelated customer data

## captures/

Contains supporting artifacts such as:

- Screen recordings
- Exported Burp messages
- HAR files
- Controlled proof-of-concept output
EOF

write_if_missing "$WORKSPACE/requests/README.md" <<'EOF'
# HTTP Requests

Store sanitized HTTP requests used to reproduce a finding.

Suggested filename:

H-001-step-03-request.txt

Remove or redact:

- Authorization headers
- Cookies
- API keys
- Personal information
EOF

write_if_missing "$WORKSPACE/responses/README.md" <<'EOF'
# HTTP Responses

Store sanitized HTTP responses paired with files in the requests directory.

Suggested filename:

H-001-step-03-response.txt

Keep only the response content needed to demonstrate the security impact.
EOF

write_if_missing "$WORKSPACE/burp/README.md" <<'EOF'
# Burp Suite

Store target-specific Burp files here.

Examples:

- Burp project files
- HackerOne scope configuration
- Target configuration
- Exported requests
- Match-and-replace rules

Before browsing:

1. Import the program's Burp configuration when available.
2. Verify included hosts manually.
3. Verify excluded hosts manually.
4. Keep the listener bound to 127.0.0.1.
5. Keep active scanning disabled unless explicitly permitted.
EOF

write_if_missing "$WORKSPACE/scripts/README.md" <<'EOF'
# Helper Scripts

Store target-specific helper scripts here.

Every script should:

- Operate only on confirmed in-scope assets.
- Enforce conservative rate limits.
- Log each request it sends.
- Avoid destructive behavior.
- Avoid embedding credentials.
- Support a dry-run mode when possible.
- Validate input before sending requests.
EOF

write_if_missing "$WORKSPACE/secrets/README.md" <<'EOF'
# Secrets

This directory is protected with mode 700.

Store temporary credentials here only when absolutely necessary.

Rules:

- Never commit this directory.
- Prefer a password manager.
- Prefer environment variables for temporary use.
- Use minimally scoped tokens.
- Use short-lived tokens when available.
- Revoke test tokens after each session.
- Never paste secrets into reports.
- Never expose secrets in screenshots.
- Never place secrets directly in shell history.
EOF

# ------------------------------------------------------------
# Print workspace tree
# ------------------------------------------------------------

printf '\n%sWorkspace tree%s\n' \
    "$BOLD_CYAN" "$RESET"

printf '%s\n' \
    "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

if command -v tree >/dev/null 2>&1; then
    tree -a -C -I '.git' "$WORKSPACE"
else
    printf '%sNotice:%s The tree command is not installed.\n' \
        "$YELLOW" "$RESET"

    printf '%sUsing find instead:%s\n\n' \
        "$GRAY" "$RESET"

    find "$WORKSPACE" \
        -mindepth 1 \
        -printf '%P\n' |
        sort

    printf '\n%sInstall tree with:%s\n' \
        "$BOLD_YELLOW" "$RESET"

    printf '  %ssudo apt install tree%s\n' \
        "$BOLD_GREEN" "$RESET"
fi

# ------------------------------------------------------------
# Explain the structure
# ------------------------------------------------------------

printf '\n%sWhat each directory and file is for%s\n' \
    "$BOLD_CYAN" "$RESET"

printf '%s\n\n' \
    "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

print_file \
    "README.md" \
    "Target summary, setup checklist, policy information and safety boundary."

print_file \
    ".gitignore" \
    "Prevents credentials, Burp files, traffic and evidence from being committed."

print_directory \
    "scope/" \
    "The source of truth for what you are authorized to test."

print_child \
    "scope.md" \
    "In-scope assets, severity limits, account requirements and restrictions."

print_child \
    "rules.md" \
    "Program rules, permitted behavior and testing conditions."

print_child \
    "out-of-scope.md" \
    "Assets and vulnerability classes that must not be tested."

print_directory \
    "notes/" \
    "Structured research and testing notes."

print_child \
    "hunting-log.md" \
    "Time-ordered record of meaningful actions during every session."

print_child \
    "endpoints.md" \
    "Inventory of discovered web and API endpoints."

print_child \
    "hypotheses.md" \
    "Testable vulnerability ideas, expectations and results."

print_child \
    "accounts.md" \
    "Controlled identities, permissions and authorization matrix."

print_directory \
    "recon/" \
    "Reconnaissance results and collected attack-surface information."

print_child \
    "raw/" \
    "Original and unchanged output directly generated by tools."

print_child \
    "processed/" \
    "Cleaned, deduplicated and categorized reconnaissance results."

print_directory \
    "evidence/" \
    "Proof and supporting material for reproducible reports."

print_child \
    "screenshots/" \
    "Redacted screenshots demonstrating the vulnerability."

print_child \
    "captures/" \
    "Videos, HAR files and exported HTTP traffic."

print_directory \
    "requests/" \
    "Sanitized HTTP requests used in reproduction steps."

print_directory \
    "responses/" \
    "Sanitized HTTP responses paired with saved requests."

print_directory \
    "burp/" \
    "Burp project files and target-specific configuration."

print_directory \
    "scripts/" \
    "Target-specific and conservatively rate-limited helper scripts."

print_directory \
    "reports/" \
    "Vulnerability reports and submission drafts."

print_child \
    "draft.md" \
    "Ready-to-fill vulnerability report template."

print_directory \
    "secrets/" \
    "Temporary sensitive files protected with permission mode 700."

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

printf '\n%sSummary%s\n' \
    "$BOLD_YELLOW" "$RESET"

printf '%s\n' \
    "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

printf '%sCreated or added:%s %s%d%s\n' \
    "$CYAN" \
    "$RESET" \
    "$GREEN" \
    "$created_count" \
    "$RESET"

printf '%sAlready existed:%s  %s%d%s\n' \
    "$CYAN" \
    "$RESET" \
    "$YELLOW" \
    "$kept_count" \
    "$RESET"

printf '%sWorkspace:%s        %s%s%s\n' \
    "$CYAN" \
    "$RESET" \
    "$BOLD_MAGENTA" \
    "$WORKSPACE" \
    "$RESET"

printf '\n%sNext commands%s\n' \
    "$BOLD_CYAN" "$RESET"

printf '  %scd "%s"%s\n' \
    "$BOLD_GREEN" \
    "$WORKSPACE" \
    "$RESET"

printf '  %snano scope/scope.md%s\n\n' \
    "$BOLD_GREEN" \
    "$RESET"
