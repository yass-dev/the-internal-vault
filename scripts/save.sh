#!/bin/bash
set -euo pipefail

# Save content to the actor's vault, encrypted with their per-user key.
# Required env: ACTOR, FILENAME, CONTENT, MASTER_KEY
# Run from: vault-data/ (vault branch checkout)

if [[ -z "${ACTOR:-}" ]] || [[ -z "${FILENAME:-}" ]] || [[ -z "${MASTER_KEY:-}" ]]; then
  echo "::error::Missing required env vars"
  exit 1
fi

# ── Validate filename ────────────────────────────────────────────
# Only simple filenames allowed (no slashes, no dots-dots)
if [[ "${FILENAME}" == */* ]] || [[ "${FILENAME}" == *..* ]] || [[ "${FILENAME}" == .* ]]; then
  echo "::error::Invalid filename: ${FILENAME}"
  exit 1
fi

KEYMAP_DIR="keymap"
VAULT_DIR="vaults/${ACTOR}"
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

# Encrypt the content with the user key and base64 encode
ENCRYPTED=$(echo -n "${CONTENT}" | openssl enc -aes-256-cbc -pbkdf2 -nosalt \
  -pass "pass:${USER_KEY}" 2>/dev/null | base64 -w0)

# Write to vault
mkdir -p "${VAULT_DIR}"
echo -n "${ENCRYPTED}" > "${VAULT_DIR}/${FILENAME}"

# Commit
git config user.name "VaultBot"
git config user.email "vault-bot@noreply.github.com"
git add "${VAULT_DIR}/${FILENAME}"
git commit -m "vault: save ${FILENAME} for ${ACTOR}"
git push

echo "Saved ${FILENAME} for ${ACTOR}."
