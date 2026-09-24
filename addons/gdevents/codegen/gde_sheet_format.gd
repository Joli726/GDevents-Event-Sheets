## Версия формата листа и обновление старых листов.
##
## Номер лежит в самом файле («format»). Когда формат меняется, сюда
## добавляется шаг «из N в N+1», а CURRENT растёт на единицу: старые листы
## обновляются при открытии и сборке, и игра, сделанная на прошлой версии
## плагина, не ломается. Лист из более новой версии не трогаем вовсе —
## сохранить его старым плагином значит молча потерять то, чего он не знает.
class_name GdeSheetFormat
extends RefCounted

## 2 — GDevents 0.4: «any», «locals», «folded», событие «include».
const CURRENT := 2

## Шаги обновления: steps()[n] переводит лист из формата n в n+1.
## Функция получает копию листа и возвращает обновлённую.
##
## Функцией, а не статической переменной: у обычного (не @tool) скрипта
## статические переменные в редакторе не инициализируются, и экспорт,
## который собирает листы в редакторе, не видел ни одного шага.
static func steps() -> Dictionary:
	return {
		# Формат 2 только добавил ключи: старый лист читается как есть. Номер
		# растёт, чтобы плагин 0.3 не открыл новый лист и не потерял «или»
		# и локальные переменные, которых он не знает.
		1: func(d: Dictionary) -> Dictionary: return d,
	}


## {"data": обновлённый лист, "from": был формат, "changed": bool, "error": ""}
static func migrate(sheet: Dictionary, with_steps: Variant = null, current: int = CURRENT) -> Dictionary:
	var steps_: Dictionary = with_steps if with_steps is Dictionary else steps()
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
		if not steps_.has(v):
			out["error"] = GdeI18n.t("нет шага обновления листа из формата %d") % v
			return out
		data = (steps_[v] as Callable).call(data)
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
