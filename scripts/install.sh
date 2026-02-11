#!/usr/bin/env bash
set -euo pipefail

APP_NAME="VoicePolishInput"
APP_BUNDLE_NAME="${APP_NAME}.app"
INSTALL_DIR="${HOME}/Applications"
APP_PATH="${INSTALL_DIR}/${APP_BUNDLE_NAME}"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

ensure_swift_toolchain() {
  if ! command -v swift >/dev/null 2>&1; then
    echo "swift not found. Install Xcode first."
    exit 1
  fi
}

setup_developer_dir_if_needed() {
  if xcodebuild -version >/dev/null 2>&1; then
    return
  fi

  if [ -d "/Applications/Xcode.app/Contents/Developer" ]; then
    export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
    echo "Using DEVELOPER_DIR=${DEVELOPER_DIR}"
  else
    echo "Xcode.app not found in /Applications. Install Xcode and run again."
    exit 1
  fi
}

build_release_binary() {
  echo "Building ${APP_NAME} (release)..."
  swift build -c release
}

create_app_bundle() {
  local binary_path="${REPO_ROOT}/.build/release/${APP_NAME}"
  if [ ! -x "$binary_path" ]; then
    echo "Built binary not found at ${binary_path}"
    exit 1
  fi

  mkdir -p "${INSTALL_DIR}"
  rm -rf "${APP_PATH}"
  mkdir -p "${APP_PATH}/Contents/MacOS"

  cp "${binary_path}" "${APP_PATH}/Contents/MacOS/${APP_NAME}"

  cat > "${APP_PATH}/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>VoicePolishInput</string>
  <key>CFBundleIdentifier</key>
  <string>com.taaaaryu.voicepolishinput</string>
  <key>CFBundleName</key>
  <string>VoicePolishInput</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>14.0</string>
  <key>LSUIElement</key>
  <true/>
</dict>
</plist>
PLIST
}

codesign_bundle() {
  if command -v codesign >/dev/null 2>&1; then
    codesign --force --deep --sign - "${APP_PATH}" >/dev/null 2>&1 || true
  fi
}

launch_app() {
  open -a "${APP_PATH}" || true
}

print_next_steps() {
  echo ""
  echo "Installed: ${APP_PATH}"
  echo "First launch requires permissions in System Settings > Privacy & Security:"
  echo "- Microphone"
  echo "- Speech Recognition"
  echo "- Accessibility"
  echo "- Input Monitoring (only if key-event fallback is enabled)"
  echo ""
  echo "Hotkey: Control + Option + Space"
}

ensure_swift_toolchain
setup_developer_dir_if_needed
build_release_binary
create_app_bundle
codesign_bundle
launch_app
print_next_steps

