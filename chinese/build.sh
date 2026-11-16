#!/bin/zsh
set -euo pipefail

PROJECT_DIR="${0:A:h}"
BUILD_DIR="$PROJECT_DIR/build"
APP_DIR="$BUILD_DIR/QuietType 中文.app"

mkdir -p "$APP_DIR/Contents/MacOS"
cp "$PROJECT_DIR/Info.plist" "$APP_DIR/Contents/Info.plist"

swiftc \
  -parse-as-library \
  -O \
  -framework AppKit \
  "$PROJECT_DIR/Sources/QuietTypeChinese/main.swift" \
  -o "$APP_DIR/Contents/MacOS/QuietTypeChinese"

codesign --force --deep --sign - "$APP_DIR"
echo "$APP_DIR"
