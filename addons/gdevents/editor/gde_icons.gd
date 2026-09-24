## Иконки редактора. Набор Tabler Icons (MIT), см. icons/LICENSE.txt.
@tool
class_name GdeIcons
extends RefCounted

const DIR := "res://addons/gdevents/icons/"

## Группа инструкций -> имя файла иконки.
const GROUP_ICONS := {
	"Движение": "move",  # i18n: ключ
	"Столкновения": "collision",  # i18n: ключ
	"Переменные": "variable",  # i18n: ключ
	"Анимация": "animation",  # i18n: ключ
	"Клавиатура": "keyboard",  # i18n: ключ
	"Мышь": "mouse",  # i18n: ключ
	"Таймеры": "timer",  # i18n: ключ
	"Объекты": "object",  # i18n: ключ
	"Сцена": "scene",  # i18n: ключ
	"Звук": "audio",  # i18n: ключ
	"Система": "system",  # i18n: ключ
	"Вид": "view",  # i18n: ключ
	"Текст": "text",  # i18n: ключ
	"Камера": "camera",  # i18n: ключ
	"Физика": "physics",  # i18n: ключ
	"Математика": "math",  # i18n: ключ
	"Выборка": "object",  # i18n: ключ
	"Сохранение": "save",  # i18n: ключ
	"Плавность": "move",  # i18n: ключ
	"Появление": "spawn",  # i18n: ключ
	"Путь": "path",  # i18n: ключ
	"Урон": "damage",  # i18n: ключ
	"Подбор": "pickup",  # i18n: ключ
	"Сетка": "layer",  # i18n: ключ
}

static var _cache: Dictionary = {}


static func get_icon(icon_name: String) -> Texture2D:
	if icon_name.is_empty():
		return null
	if _cache.has(icon_name):
		return _cache[icon_name]
	var p := DIR + icon_name + ".svg"
	var tex: Texture2D = null
	if ResourceLoader.exists(p):
		tex = load(p)
	_cache[icon_name] = tex
	return tex


## Иконка инструкции: явное поле icon, иначе по группе,
## иначе общая заглушка по виду (условие или действие).
static func for_instruction(def: Variant, kind: String) -> Texture2D:
	if def is Dictionary:
		var d: Dictionary = def
		var explicit := str(d.get("icon", ""))
		if not explicit.is_empty():
			var t := get_icon(explicit)
			if t != null:
				return t
		var g := str(d.get("group", ""))
		if GROUP_ICONS.has(g):
			return get_icon(GROUP_ICONS[g])
		if not g.is_empty():
			# Группа без карты — это имя поведения.
			return get_icon("behavior")
	return get_icon("condition" if kind == "conditions" else "action")


## Группа приходит уже переведённой («Movement»), а в таблице — русские
## названия: сверяем и так, и в переводе.
static func for_group(group: String) -> Texture2D:
	if GROUP_ICONS.has(group):
		return get_icon(GROUP_ICONS[group])
	for k: String in GROUP_ICONS:
		if GdeI18n.t(k) == group:
			return get_icon(GROUP_ICONS[k])
	return get_icon("behavior")


static func for_event_type(t: String) -> Texture2D:
	match t:
		"comment": return get_icon("comment")
		"group": return get_icon("group")
		"foreach": return get_icon("foreach")
		"repeat": return get_icon("repeat")
		"while": return get_icon("refresh")
		_: return null
