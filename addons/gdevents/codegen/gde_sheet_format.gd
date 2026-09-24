## Версия формата листа и обновление старых листов.
##
## Номер лежит в самом файле («format»). Когда формат меняется, сюда
## добавляется шаг «из N в N+1», а CURRENT растёт на единицу: старые листы
## обновляются при открытии и сборке, и игра, сделанная на прошлой версии
## плагина, не ломается. Лист из более новой версии не трогаем вовсе —
## сохранить его старым плагином значит молча потерять то, чего он не знает.
class_name GdeSheetFormat
extends RefCounted

const CURRENT := 1

## Шаги обновления: STEPS[n] переводит лист из формата n в n+1.
## Функция получает копию листа и возвращает обновлённую.
static var STEPS: Dictionary = {}


## {"data": обновлённый лист, "from": был формат, "changed": bool, "error": ""}
static func migrate(sheet: Dictionary, steps: Dictionary = STEPS, current: int = CURRENT) -> Dictionary:
	var from := version_of(sheet)
	var out := {"data": sheet, "from": from, "changed": false, "error": ""}
	if from < 1:
		out["error"] = GdeI18n.t("«format» должен быть целым числом от 1, а не %s") % str(sheet.get("format"))
		return out
	if from > current:
		out["error"] = GdeI18n.t("лист сделан в более новой версии GDevents (формат %d, этот плагин понимает до %d) — обновите плагин") % [from, current]
		return out
	var data := sheet.duplicate(true)
	var v := from
	while v < current:
		if not steps.has(v):
			out["error"] = GdeI18n.t("нет шага обновления листа из формата %d") % v
			return out
		data = (steps[v] as Callable).call(data)
		v += 1
		data["format"] = v
	# Лист без номера — из самых первых версий: формат 1, но номер допишем.
	if not sheet.has("format"):
		data["format"] = v
	out["data"] = data
	out["changed"] = v != from or not sheet.has("format")
	return out


## Номер формата листа; без «format» — 1, мусор — 0.
static func version_of(sheet: Dictionary) -> int:
	if not sheet.has("format"):
		return 1
	var f: Variant = sheet["format"]
	if (f is int) or (f is float and is_equal_approx(f, roundf(f))):
		return int(f)
	return 0
