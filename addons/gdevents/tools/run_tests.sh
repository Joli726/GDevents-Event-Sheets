#!/bin/bash
# Все тесты плагина одной командой (из корня репозитория):
#
#   bash addons/gdevents/tools/run_tests.sh
#
# Код выхода 0 — всё прошло, 1 — хоть что-то упало. Этим же скриптом
# тесты гоняет GitHub на каждом PR. Godot берётся из $GODOT или godot.
set -u
GODOT=${GODOT:-godot}
cd "$(dirname "$0")/../../.."
LOG=${GDE_TEST_LOGS:-$(mktemp -d)}
mkdir -p "$LOG"
failed=()

echo "== импорт проекта"
timeout 900 "$GODOT" --headless --import >"$LOG/import.log" 2>&1
n=$(grep -cE "SCRIPT ERROR|Parse Error" "$LOG/import.log")
if [ "$n" -ne 0 ]; then
	echo "  ✗ ошибок скриптов при импорте: $n"
	grep -E "SCRIPT ERROR|Parse Error" -A2 "$LOG/import.log" | head -20
	failed+=(import)
fi

# run <имя> <что должно быть в выводе> <аргументы godot…>
run() {
	local name=$1 want=$2
	shift 2
	echo "== $name"
	timeout 900 "$GODOT" --headless "$@" >"$LOG/$name.log" 2>&1
	local code=$?
	local summary
	summary=$(grep -E "проверок|ИТОГ" "$LOG/$name.log" | tail -1)
	echo "  ${summary:-(нет итога)}  [код $code]"
	if [ $code -ne 0 ] || grep -q "✗" "$LOG/$name.log" \
			|| grep -qE "провалено: [1-9]" "$LOG/$name.log" \
			|| ! grep -qE "$want" "$LOG/$name.log"; then
		grep -E "✗" -A6 "$LOG/$name.log" | head -30
		[ $code -eq 124 ] && echo "  ✗ не уложился во время"
		failed+=("$name")
	fi
}

OK="провалено: 0"
run i18n      "$OK" --script res://addons/gdevents/tools/i18n_test.gd
run editor    "$OK" --script res://addons/gdevents/tools/editor_test.gd
run behavior  "$OK" --quit-after 600 res://addons/gdevents/tools/behavior_test.tscn
run hover     "$OK" res://addons/gdevents/tools/hover_test.tscn
run build     "✓ selftest.gdes.json" --script res://addons/gdevents/tools/build_tests.gd
run selftest  "ИТОГ врагов=2 уехал=1 остался=1 пуля=[1-9][0-9.]* скорость=100" --quit-after 200 res://addons/gdevents/tests/selftest.tscn
run runtime   "$OK" --quit-after 600 res://addons/gdevents/tools/runtime_test.tscn
run library   "$OK" --quit-after 5000 res://addons/gdevents/tools/library_test.tscn
run window    "$OK" --quit-after 2500 res://addons/gdevents/tools/behavior_window_test.tscn
run scenarios "$OK" --quit-after 60000 res://addons/gdevents/tools/behavior_scenarios_test.tscn
run events    "$OK" --quit-after 20000 res://addons/gdevents/tools/events_test.tscn
run check     "." --quit-after 5000 res://addons/gdevents/tools/check.tscn

echo "== export"
if GODOT=$GODOT bash addons/gdevents/tools/export_test.sh >"$LOG/export.log" 2>&1; then
	tail -1 "$LOG/export.log"
else
	cat "$LOG/export.log" | tail -40
	failed+=(export)
fi

echo
if [ ${#failed[@]} -eq 0 ]; then
	echo "ВСЕ ТЕСТЫ ПРОШЛИ"
	exit 0
fi
echo "УПАЛИ: ${failed[*]}  (логи: $LOG)"
exit 1
