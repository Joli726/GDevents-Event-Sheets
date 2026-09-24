#!/bin/bash
# Тест экспорта: листы пересобираются перед экспортом, и игра из .pck
# работает без редактора.
#
#   bash addons/gdevents/tools/export_test.sh      (из корня репозитория)
#
# Шаблоны экспорта не нужны: собирается только .pck (--export-pack), а
# запускается он тем же godot через --main-pack. Проект копируется во
# временную папку, репозиторий не трогается.
set -u
GODOT=${GODOT:-godot}
ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
P=$TMP/proj
mkdir -p "$P"
(cd "$ROOT" && tar --exclude=.git --exclude=.godot -cf - project.godot addons) | tar -xf - -C "$P"

mkdir -p "$P/game"
cat > "$P/game/main.gdes.json" <<'EOF'
{
  "format": 1,
  "name": "main",
  "extends": "Node2D",
  "objects": [],
  "variables": {},
  "events": [
    {
      "type": "standard",
      "conditions": [{ "id": "system.at_start", "params": [] }],
      "actions": [
        { "id": "system.print", "params": ["\"GDE_EXPORT_FRESH\""] },
        { "id": "system.quit", "params": [] }
      ]
    }
  ]
}
EOF
# Старый собранный код: если экспорт не пересоберёт лист, игра напечатает его.
cat > "$P/game/main.gd" <<'EOF'
extends Node2D
func _ready() -> void:
	print("GDE_EXPORT_STALE")
	get_tree().quit()
EOF
cat > "$P/game/probe.gd" <<'EOF'
extends Node
func _ready() -> void:
	print("GDE_EXPORT_EN_JSON=", FileAccess.file_exists("res://addons/gdevents/i18n/en.json"))
EOF
cat > "$P/game/main.tscn" <<'EOF'
[gd_scene format=3]

[ext_resource type="Script" path="res://game/main.gd" id="1"]
[ext_resource type="Script" path="res://game/probe.gd" id="2"]

[node name="Main" type="Node2D"]
script = ExtResource("1")

[node name="Probe" type="Node" parent="."]
script = ExtResource("2")
EOF
sed -i 's|^config/name="GDevents"|config/name="GDevents"\nrun/main_scene="res://game/main.tscn"|' "$P/project.godot"
cat > "$P/export_presets.cfg" <<'EOF'
[preset.0]

name="Linux"
platform="Linux"
runnable=true
export_filter="all_resources"
include_filter=""
exclude_filter=""
export_path=""

[preset.0.options]
EOF

fail=0
total=0
check() { total=$((total+1)); if [ "$1" = 1 ]; then echo "  ✓ $2"; else echo "  ✗ $2"; fail=$((fail+1)); fi; }

(cd "$P" && timeout 600 "$GODOT" --headless --import >"$TMP/import.log" 2>&1)
(cd "$P" && timeout 600 "$GODOT" --headless --export-pack Linux "$TMP/game.pck" >"$TMP/export.log" 2>&1)
check "$([ -s "$TMP/game.pck" ] && echo 1)" "экспорт собрал game.pck"
check "$(grep -q GDE_EXPORT_FRESH "$P/game/main.gd" && echo 1)" "лист пересобран перед экспортом"

mkdir -p "$TMP/run" && cd "$TMP/run"
out=$(timeout 120 "$GODOT" --headless --main-pack "$TMP/game.pck" 2>&1)
check "$(echo "$out" | grep -q GDE_EXPORT_FRESH && echo 1)" "игра из .pck идёт по свежему коду листа"
check "$(echo "$out" | grep -q GDE_EXPORT_STALE || echo 1)" "старого кода в игре нет"
check "$(echo "$out" | grep -q 'GDE_EXPORT_EN_JSON=true' && echo 1)" "переводы en.json попали в игру"
check "$(echo "$out" | grep -qE 'SCRIPT ERROR|Parse Error' || echo 1)" "игра запускается без ошибок скриптов"

if [ $fail -ne 0 ]; then
	echo "—— лог экспорта ——"; tail -30 "$TMP/export.log"
	echo "—— вывод игры ——"; echo "$out" | tail -30
fi
echo "—— проверок экспорта: $total, провалено: $fail"
[ $fail -eq 0 ]
