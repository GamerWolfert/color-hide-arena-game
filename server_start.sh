#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_BIN="${SERVER_BIN:-${ROOT_DIR}/builds/server/color_hide_arena_server.x86_64}"
PORT="${COLOR_HIDE_ARENA_PORT:-24590}"

if [[ ! -x "${SERVER_BIN}" ]]; then
  echo "Server executable ontbreekt of is niet uitvoerbaar: ${SERVER_BIN}" >&2
  exit 1
fi

exec "${SERVER_BIN}" --headless -- --server --port="${PORT}"
