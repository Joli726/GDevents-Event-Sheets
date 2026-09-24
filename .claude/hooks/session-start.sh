#!/bin/bash
# Облачные сессии Claude Code: ставит Godot 4.7.1 без окна, чтобы в каждой
# сессии сразу работали проверка своих файлов (tools/check.tscn) и тесты
# плагина. На своём компьютере ничего не делает — там Godot уже есть.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

VERSION="4.7.1-stable"
DIR="${GODOT_HOME:-$HOME/.local/share/godot-$VERSION}"
BIN="$DIR/Godot_v${VERSION}_linux.x86_64"
URL="https://github.com/godotengine/godot-builds/releases/download/${VERSION}/Godot_v${VERSION}_linux.x86_64.zip"

if [ ! -x "$BIN" ]; then
  mkdir -p "$DIR"
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT
  curl -fsSL --retry 4 --retry-delay 2 -o "$tmp/godot.zip" "$URL"
  unzip -q -o "$tmp/godot.zip" -d "$DIR"
  chmod +x "$BIN"
fi

# Команда godot: ссылка в /usr/local/bin, а где туда нельзя — через PATH.
mkdir -p "$DIR/bin"
ln -sf "$BIN" "$DIR/bin/godot"
if [ -w /usr/local/bin ]; then
  ln -sf "$BIN" /usr/local/bin/godot
fi
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"$DIR/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi

# Импорт проекта: без папки .godot Godot не знает классов плагина, и
# проверки падали бы на первой же строке. Повторный импорт почти мгновенный.
cd "${CLAUDE_PROJECT_DIR:-$(pwd)}"
timeout 900 "$BIN" --headless --import > /dev/null 2>&1 || true

echo "GDevents: Godot 4.7.1 is installed as 'godot'. Check a file with: godot --headless --quit-after 5000 res://addons/gdevents/tools/check.tscn -- <res://path>"
