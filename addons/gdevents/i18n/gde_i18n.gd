## Языки плагина. Сейчас два — английский и русский; новый добавляется
## одним файлом i18n/<код>.json и строчкой в LANGUAGES.
##
## Исходный текст в коде плагина — русский, и он же ключ перевода:
##   GdeI18n.t("Объекты листа")  -> "Sheet objects", если выбран английский,
##                                 -> сам текст, если русский.
## Переводы лежат в i18n/<код>.json: {"русский текст": "перевод"}. Чего в
## переводе нет, показывается как есть — поэтому i18n_test следит, чтобы
## у каждой строки интерфейса перевод был.
##
## Язык выбирает человек, у каждого свой: это настройка редактора
## gdevents/language, а не проекта. Игра, запущенная из редактора, узнаёт
## его из user:// (туда его кладёт плагин перед запуском); собранная игра —
## по языку системы.
@tool
class_name GdeI18n
extends RefCounted

const SETTING := "gdevents/language"
## Порядок — как в выпадающих списках.
const LANGUAGES: Array[String] = ["en", "ru"]
const NAMES := {"en": "English", "ru": "Русский"}
const DEFAULT := "en"
## Язык, на котором написан исходный текст в коде.
const SOURCE := "ru"
const DIR := "res://addons/gdevents/i18n/"
const RUNTIME_FILE := "user://gdevents_language.txt"

static var _language: String = ""
static var _catalogs: Dictionary = {}


static func language() -> String:
	if _language.is_empty():
		_language = _detect()
	return _language


## Сменить язык. persist — запомнить выбор в настройках редактора.
static func set_language(code: String, persist: bool = true) -> void:
	if not LANGUAGES.has(code):
		code = DEFAULT
	_language = code
	if persist:
		var es := _editor_settings()
		if es != null:
			es.call("set_setting", SETTING, code)
		write_runtime_language()


## Выбирал ли человек язык хоть раз — иначе при первом запуске спросим.
static func is_chosen() -> bool:
	var es := _editor_settings()
	return es != null and bool(es.call("has_setting", SETTING))


## Перевести строку интерфейса. text — исходный русский текст.
static func t(text: String) -> String:
	var lang := language()
	if lang == SOURCE or text.is_empty():
		return text
	var v: Variant = catalog(lang).get(text)
	return v if v is String and not (v as String).is_empty() else text


## Словарь перевода языка lang: {"русский текст": "перевод"}.
static func catalog(lang: String) -> Dictionary:
	if not _catalogs.has(lang):
		var d: Dictionary = {}
		var path := DIR + lang + ".json"
		if FileAccess.file_exists(path):
			var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
			if v is Dictionary:
				d = v
		_catalogs[lang] = d
	return _catalogs[lang]


## Забыть загруженные переводы — после правки файла перевода.
static func reload() -> void:
	_catalogs.clear()


## Текст на нужном языке из пар вида {"": "по умолчанию", "en": "...", "ru": "..."}:
## так хранят переводы поведения и расширения — прямо в своём файле.
static func pick(variants: Dictionary, lang: String = "") -> String:
	if lang.is_empty():
		lang = language()
	if variants.has(lang) and not str(variants[lang]).is_empty():
		return str(variants[lang])
	return str(variants.get("", ""))


## Язык для игры, запущенной из редактора: у неё нет настроек редактора,
## зато user:// у них общий.
static func write_runtime_language() -> void:
	var f := FileAccess.open(RUNTIME_FILE, FileAccess.WRITE)
	if f != null:
		f.store_string(language())
		f.close()


static func _detect() -> String:
	var es := _editor_settings()
	if es != null and bool(es.call("has_setting", SETTING)):
		var v := str(es.call("get_setting", SETTING))
		if LANGUAGES.has(v):
			return v
	if es != null:
		# В редакторе до первого выбора — английский, как и предложено в окне выбора.
		return DEFAULT
	if not Engine.is_editor_hint() and FileAccess.file_exists(RUNTIME_FILE):
		var r := FileAccess.get_file_as_string(RUNTIME_FILE).strip_edges()
		if LANGUAGES.has(r):
			return r
	# Первый запуск или собранная игра — по языку системы.
	return "ru" if OS.get_locale_language() == "ru" else DEFAULT


static func _editor_settings() -> Object:
	if not Engine.is_editor_hint() or not Engine.has_singleton("EditorInterface"):
		return null
	return (Engine.get_singleton("EditorInterface") as Object).call("get_editor_settings")
