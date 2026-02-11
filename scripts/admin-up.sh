#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

DATA_DIR="${HOME}/Library/Application Support/VoicePolishInput"
STATE_PATH="${DATA_DIR}/state.json"
export VOICE_POLISH_DATA_DIR="${DATA_DIR}"

mkdir -p "${DATA_DIR}"
if [ ! -f "${STATE_PATH}" ]; then
  cat > "${STATE_PATH}" <<'JSON'
{
  "fillerWords": ["えー", "え〜", "えぇ", "あの", "あのー", "あの〜", "えっと", "えっとー", "えっと〜", "その", "そのー", "その〜", "なんか"],
  "replacementEntries": [],
  "historyEntries": []
}
JSON
fi

docker compose -f docker-compose.admin.yml up -d --build
echo "Admin UI: http://localhost:8765"

