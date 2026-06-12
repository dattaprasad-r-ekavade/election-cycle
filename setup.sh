#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

GODOT_VERSION="${GODOT_VERSION:-4.6.3}"
GODOT_DIR="${GODOT_DIR:-$HOME/.local/bin}"
GODOT_BIN="${GODOT_BIN:-$GODOT_DIR/Godot_v${GODOT_VERSION}-stable_linux.x86_64}"

echo "==> Election Cycle setup"

if [[ ! -x "$GODOT_BIN" ]]; then
  echo "==> Installing Godot ${GODOT_VERSION} to ${GODOT_DIR}"
  mkdir -p "$GODOT_DIR"
  tmp_zip="$(mktemp)"
  curl -fsSL \
    "https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" \
    -o "$tmp_zip"
  unzip -qo "$tmp_zip" -d "$GODOT_DIR"
  chmod +x "$GODOT_BIN"
  rm -f "$tmp_zip"
fi

export PATH="$GODOT_DIR:$PATH"

echo "==> Godot: $($GODOT_BIN --version)"
echo "==> Importing assets (first run builds .godot cache)"
"$GODOT_BIN" --headless --path "$ROOT_DIR" --import

echo "==> Running flow validation"
"$GODOT_BIN" --headless --path "$ROOT_DIR" -s res://tests/windows_flow_validation.gd

echo "==> Running seed determinism test"
"$GODOT_BIN" --headless --path "$ROOT_DIR" -s res://tests/run_seed_test.gd

cat <<'EOF'

Setup complete.

Run the game:
  godot --path .

Headless smoke test:
  godot --headless --path . --quit-after 3

Run tests:
  godot --headless -s res://tests/windows_flow_validation.gd
  godot --headless -s res://tests/run_seed_test.gd
EOF
