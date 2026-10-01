#!/bin/bash
set -euo pipefail

# Onboard a new actor: generate a per-user key and encrypt it with MASTER_KEY.
# Required env: ACTOR, MASTER_KEY
# Run from: vault-data/ (vault branch checkout)

if [[ -z "${ACTOR:-}" ]] || [[ -z "${MASTER_KEY:-}" ]]; then
  echo "::error::Missing ACTOR or MASTER_KEY"
  exit 1
fi

KEYMAP_DIR="keymap"
VAULT_DIR="vaults/${ACTOR}"

# Skip if already onboarded
if [[ -f "${KEYMAP_DIR}/${ACTOR}.key" ]]; then
  echo "Actor ${ACTOR} is already onboarded."
  exit 0
fi

# Generate a random 32-byte user key
USER_KEY=$(openssl rand -hex 32)

# Encrypt the user key with MASTER_KEY and store it
echo -n "${USER_KEY}" | openssl enc -aes-256-cbc -pbkdf2 -salt \
  -pass "pass:${MASTER_KEY}" -out "${KEYMAP_DIR}/${ACTOR}.key"

# Create the vault directory with a .gitkeep
mkdir -p "${VAULT_DIR}"
touch "${VAULT_DIR}/.gitkeep"

# Commit
git config user.name "VaultBot"
git config user.email "vault-bot@noreply.github.com"
git add "${KEYMAP_DIR}/${ACTOR}.key" "${VAULT_DIR}/.gitkeep"
git commit -m "vault: init ${ACTOR}"
git push

echo "Onboarded ${ACTOR}."
