#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

DATA_DIR="${HOME}/Library/Application Support/VoicePolishInput"
export VOICE_POLISH_DATA_DIR="${DATA_DIR}"

docker compose -f docker-compose.admin.yml down

