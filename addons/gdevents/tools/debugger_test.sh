#!/bin/bash
# Тест отладчика событий: игра, запущенная с отладчиком Godot, присылает
# сработавшие события и переменные. Вместо редактора их принимает
# tools/debugger_server.gd.
#
#   bash addons/gdevents/tools/debugger_test.sh      (из корня репозитория)
set -u
GODOT=${GODOT:-godot}
ROOT=$(cd "$(dirname "$0")/../../.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
P=$TMP/proj
mkdir -p "$P/game"
(cd "$ROOT" && tar --exclude=.git --exclude=.godot -cf - project.godot addons) | tar -xf - -C "$P"
cat > "$P/game/main.gdes.json" <<'JSON'
{
  "format": 2,
  "objects": [],
  "variables": {"ticks": 0},
  "events": [
    {"type": "standard", "conditions": [], "actions": [{"id": "var.modify", "params": ["ticks", "+", "1"]}]},
    {"type": "standard", "conditions": [{"id": "system.compare", "params": ["1", "=", "2"]}],
     "actions": [{"id": "var.modify", "params": ["never", "=", "1"]}]}
  ]
}
JSON
cat > "$P/game/main.tscn" <<'TSCN'
[gd_scene format=3]

[ext_resource type="Script" path="res://game/main.gd" id="1"]

[node name="Main" type="Node2D"]
script = ExtResource("1")
TSCN
sed -i 's|^config/name="GDevents"|config/name="GDevents"\nrun/main_scene="res://game/main.tscn"|' "$P/project.godot"

fail=0
total=0
check() { total=$((total+1)); if [ "$1" = 1 ]; then echo "  ✓ $2"; else echo "  ✗ $2"; fail=$((fail+1)); fi; }

(cd "$P" && timeout 600 "$GODOT" --headless --import >/dev/null 2>&1)
(cd "$P" && timeout 300 "$GODOT" --headless --script res://addons/gdevents/tools/build_cli.gd >"$TMP/build.log" 2>&1)
check "$(grep -q 'dbg_hit' "$P/game/main.gd" && echo 1)" "собранный лист сообщает отладчику о событиях"

PORT=$((20000 + RANDOM % 20000))
(cd "$P" && timeout 120 "$GODOT" --headless --script res://addons/gdevents/tools/debugger_server.gd -- $PORT 40 >"$TMP/server.log" 2>&1) &
SRV=$!
for i in $(seq 1 50); do grep -q GDE_DBG_LISTENING "$TMP/server.log" 2>/dev/null && break; sleep 0.2; done
(cd "$P" && timeout 120 "$GODOT" --headless --remote-debug tcp://127.0.0.1:$PORT --quit-after 90 res://game/main.tscn >"$TMP/game.log" 2>&1)
wait $SRV
out=$(cat "$TMP/server.log")
check "$(echo "$out" | grep -q GDE_DBG_CONNECTED && echo 1)" "игра подключилась к отладчику"
check "$(echo "$out" | grep -q GDE_DBG_STATE && echo 1)" "игра присылает снимки GDevents"
check "$(echo "$out" | grep 'GDE_DBG_STATE' | grep -q 'main.gdes.json\":\[\[\[0\]' && echo 1)" "сработавшее событие 1 — в снимке"
check "$(echo "$out" | grep 'GDE_DBG_STATE' | grep -q '\[\[1\]' && echo 0 || echo 1)" "несработавшего события 2 в снимке нет"
check "$(echo "$out" | grep 'GDE_DBG_STATE' | tail -1 | grep -qE '"ticks":[1-9]' && echo 1)" "переменные сцены — живые значения"

if [ $fail -ne 0 ]; then
	echo "—— сервер ——"; tail -20 "$TMP/server.log"
	echo "—— игра ——"; tail -20 "$TMP/game.log"
fi
echo "—— проверок отладчика: $total, провалено: $fail"
[ $fail -eq 0 ]
