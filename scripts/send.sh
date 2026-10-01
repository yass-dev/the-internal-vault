#!/bin/bash
set -euo pipefail

# Decrypt a vault file and deliver its content to a URL.
# Required env: ACTOR, FILENAME, MASTER_KEY
# Optional env: DEST_URL, SEND_URL
# Run from: $GITHUB_WORKSPACE (vault branch checked out at workspace root)

if [[ -z "${ACTOR:-}" ]] || [[ -z "${FILENAME:-}" ]] || [[ -z "${MASTER_KEY:-}" ]]; then
  echo "::error::Missing required env vars"
  exit 1
fi

URL="${DEST_URL:-${SEND_URL:-}}"
if [[ -z "${URL}" ]]; then
  echo "::error::No destination URL"
  exit 1
fi

KEYMAP_DIR="keymap"
KEY_FILE="${KEYMAP_DIR}/${ACTOR}.key"

if [[ ! -f "${KEY_FILE}" ]]; then
  echo "::error::Actor ${ACTOR} is not onboarded"
  exit 1
fi

# Decrypt the per-user key
USER_KEY=$(openssl enc -d -aes-256-cbc -pbkdf2 \
  -pass "pass:${MASTER_KEY}" -in "${KEY_FILE}" 2>/dev/null) || {
  echo "::error::Failed to decrypt user key"
  exit 1
}

# ── Resolve the file ─────────────────────────────────────────────
FILE="vaults/${ACTOR}/${FILENAME}"

if [[ ! -f "${FILE}" ]]; then
  echo "::error::File not found: ${FILE}"
  exit 1
fi

# Read vault file content
CONTENT=$(cat "${FILE}")

# Decrypt: base64-decode then AES decrypt with user key
PLAINTEXT=$(echo -n "${CONTENT}" | base64 -d 2>/dev/null \
  | openssl enc -d -aes-256-cbc -pbkdf2 -nosalt \
    -pass "pass:${USER_KEY}" 2>/dev/null) || PLAINTEXT=""

# If decryption succeeded, send plaintext; otherwise send raw content
if [[ -n "${PLAINTEXT}" ]]; then
  curl -s -X POST -d "${PLAINTEXT}" "${URL}"
else
  curl -s -X POST -d "${CONTENT}" "${URL}"
fi
