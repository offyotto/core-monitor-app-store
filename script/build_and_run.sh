#!/usr/bin/env bash

set -euo pipefail

MODE="${1:-run}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/core-monitor-app-store.xcodeproj"
SCHEME="core-monitor-app-store"
APP_NAME="core-monitor"
DERIVED_DATA_PATH="$ROOT_DIR/build/DerivedData"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/Debug/$APP_NAME.app"
APP_BINARY="$APP_PATH/Contents/MacOS/$APP_NAME"

XCODEBUILD_ARGS=(
  -project "$PROJECT_PATH"
  -scheme "$SCHEME"
  -configuration Debug
  -derivedDataPath "$DERIVED_DATA_PATH"
)

if [[ "${CORE_MONITOR_UNSIGNED_BUILD:-0}" == "1" ]]; then
  XCODEBUILD_ARGS+=(CODE_SIGNING_ALLOWED=NO)
else
  XCODEBUILD_ARGS+=(-allowProvisioningUpdates)
fi

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

xcodebuild "${XCODEBUILD_ARGS[@]}" build

if [[ ! -d "$APP_PATH" ]]; then
  echo "Built app not found at $APP_PATH" >&2
  exit 1
fi

if [[ ! -x "$APP_BINARY" ]]; then
  echo "Built executable not found at $APP_BINARY" >&2
  exit 1
fi

open_app() {
  /usr/bin/open -n "$APP_PATH"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --verify|verify)
    open_app
    sleep 2
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
