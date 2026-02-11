#!/usr/bin/env bash
set -euo pipefail

APP_PATH="${HOME}/Applications/VoicePolishInput.app"

if [ -d "${APP_PATH}" ]; then
  rm -rf "${APP_PATH}"
  echo "Removed ${APP_PATH}"
else
  echo "Not installed: ${APP_PATH}"
fi

