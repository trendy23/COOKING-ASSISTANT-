#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter is required to build the offline release package." >&2
  exit 1
fi

flutter pub get
flutter test
flutter build apk --release

printf "\nOffline Android APK is available in:\n"
printf "  %s/build/app/outputs/flutter-apk\n" "$ROOT_DIR"
