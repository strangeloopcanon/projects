#!/usr/bin/env bash
set -euo pipefail

# Export all repositories (including private) for an owner into projects.json
# Requires: GitHub CLI `gh` authenticated with access to the private repos.

OWNER="${1:-strangeloopcanon}"
OUT_FILE="${2:-projects.json}"

if ! command -v gh >/dev/null 2>&1; then
  echo "Error: gh (GitHub CLI) not found" >&2
  exit 1
fi

# Verify auth (non-fatal if it fails; gh will error on list)
gh auth status -h github.com >/dev/null 2>&1 || true

TMP_FILE="$(mktemp)"
trap 'rm -f "${TMP_FILE}"' EXIT

# Fetch repos with desired fields
gh repo list "$OWNER" \
  --limit 300 \
  --source \
  --no-archived \
  --json name,description,createdAt,updatedAt,pushedAt,isPrivate,isFork,isArchived,stargazerCount,homepageUrl,repositoryTopics,url,owner \
  > "${TMP_FILE}"

# Filter to owned, non-fork, non-archived; normalize to the shape the page expects
jq --arg owner "$OWNER" '
  map(
    select((.owner.login // "") | ascii_downcase == ($owner | ascii_downcase)) |
    select((.isFork | not) and (.isArchived | not)) |
    {
      name: .name,
      html_url: .url,
      created_at: .createdAt,
      description: (.description // ""),
      topics: ((.repositoryTopics.nodes // []) | map(.topic.name)),
      stargazers_count: (.stargazerCount // 0),
      pushed_at: (.pushedAt // ""),
      private: (.isPrivate // false)
    }
  )
' "${TMP_FILE}" > "${OUT_FILE}"

echo "Wrote ${OUT_FILE} for owner ${OWNER}" >&2
