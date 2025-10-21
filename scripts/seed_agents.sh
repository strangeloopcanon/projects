#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 [-f] <target_dir>" >&2
  echo "  -f  force overwrite existing files" >&2
}

FORCE=0
while getopts ":fh" opt; do
  case $opt in
    f) FORCE=1 ;;
    h) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
done
shift $((OPTIND-1))

if [ $# -ne 1 ]; then
  usage
  exit 2
fi

TARGET_DIR="$1"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

SRC_AGENTS="${REPO_ROOT}/AGENTS.md"
SRC_CONFIG="${REPO_ROOT}/.agents.yml"

if [ ! -f "${SRC_AGENTS}" ]; then
  echo "Error: AGENTS.md not found at repo root: ${SRC_AGENTS}" >&2
  exit 1
fi

mkdir -p "${TARGET_DIR}"

copy_file() {
  local src="$1" dst="$2"
  if [ ! -f "$src" ]; then
    return 0
  fi
  if [ -f "$dst" ] && [ "$FORCE" -ne 1 ]; then
    echo "Skip (exists): ${dst}" >&2
  else
    cp -f "$src" "$dst"
    echo "Copied: $(basename "$src") → ${dst}" >&2
  fi
}

copy_file "${SRC_AGENTS}" "${TARGET_DIR}/AGENTS.md"
copy_file "${SRC_CONFIG}" "${TARGET_DIR}/.agents.yml"

echo "Done. Seeded policy files into ${TARGET_DIR}" >&2

