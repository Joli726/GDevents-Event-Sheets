@tool
extends EditorPlugin

const AUTOLOAD_NAME := "Gde"
const AUTOLOAD_PATH := "res://addons/gdevents/runtime/gde_runtime.gd"


var _panel: GdeEventSheetPanel
## Пункт меню «Проект → Инструменты» — на языке, выбранном при его создании.
var _menu_item: String = ""
var _language_dialog: GdeLanguageDialog
var _export_plugin: GdeExportPlugin
var _debugger_plugin: GdeDebuggerPlugin


## Автозагрузка — часть настроек проекта, а не сеанса редактора. Её ставят
## при включении плагина и убирают при выключении; раньше это делалось в
## _enter_tree/_exit_tree, то есть при каждом открытии и закрытии редактора.
func _enable_plugin() -> void:
	_ensure_autoload()


func _disable_plugin() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)


## Ставить уже стоящую автозагрузку незачем: это лишняя правка настроек
## проекта при каждом открытии редактора.
func _ensure_autoload() -> void:
	if not ProjectSettings.has_setting("autoload/" + AUTOLOAD_NAME):
		add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)


func _enter_tree() -> void:
	# Плагин включён, а Gde в проекте нет (удалили руками или её снял
	# _exit_tree прежней версии) — без неё не собирается ни один лист.
	_ensure_autoload()
	_add_menu()
	_create_panel()
	_export_plugin = GdeExportPlugin.new()
	_export_plugin.panel = _panel
	add_export_plugin(_export_plugin)
	_debugger_plugin = GdeDebuggerPlugin.new()
	_debugger_plugin.panel = _panel
	add_debugger_plugin(_debugger_plugin)

	# Язык плагина: при первом запуске спросим, дальше — переключатель на
	# панели или «Настройки редактора → GDevents».
	var es := EditorInterface.get_editor_settings()
	if GdeI18n.is_chosen():
		_register_language_setting()
	es.settings_changed.connect(_on_editor_settings_changed)
	_ask_language_once.call_deferred()


func _exit_tree() -> void:
	_remove_menu()
	if _export_plugin != null:
		remove_export_plugin(_export_plugin)
		_export_plugin = null
	if _debugger_plugin != null:
		remove_debugger_plugin(_debugger_plugin)
		_debugger_plugin = null
	var es := EditorInterface.get_editor_settings()
	if es.settings_changed.is_connected(_on_editor_settings_changed):
		es.settings_changed.disconnect(_on_editor_settings_changed)
	if is_instance_valid(_language_dialog):
		_language_dialog.queue_free()
	if is_instance_valid(_panel):
		_panel.queue_free()
	_panel = null


func _add_menu() -> void:
	_menu_item = GdeI18n.t("GDevents: пересобрать листы событий")
	add_tool_menu_item(_menu_item, _rebuild)


func _remove_menu() -> void:
	if not _menu_item.is_empty():
		remove_tool_menu_item(_menu_item)
	_menu_item = ""


func _create_panel() -> void:
	_panel = GdeEventSheetPanel.new()
	_panel.name = "GDevents"
	# Главный экран редактора — контейнер, и он игнорирует якоря: без флагов
	# растяжения панель схлопывается по высоте тулбара, а список событий
	# обрезается в ноль. Якоря оставлены на случай не-контейнерного родителя.
	_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel.language_changed.connect(_apply_language)
	EditorInterface.get_editor_main_screen().add_child(_panel)
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.hide()


# ------------------------------------------------------------------- язык ---

## Первый запуск: язык ещё не выбирали — спросить. По умолчанию английский.
func _ask_language_once() -> void:
	if GdeI18n.is_chosen():
		return
	for i in range(3):
		await get_tree().process_frame
	_language_dialog = GdeLanguageDialog.new()
	_language_dialog.chosen.connect(_apply_language)
	EditorInterface.get_base_control().add_child(_language_dialog)
	_language_dialog.ask()


## Сменить язык: всё, что построено на старом, строится заново. Лист перед
## этим сохраняется, открытый лист и видимость вкладки сохраняются тоже.
func _apply_language(code: String) -> void:
	GdeI18n.set_language(code)
	_register_language_setting()
	var sheet := ""
	var shown := false
	if is_instance_valid(_panel):
		_panel.save_if_dirty()
		sheet = _panel.doc.path if _panel.doc != null else ""
		shown = _panel.visible
		_panel.queue_free()
	_remove_menu()
	_add_menu()
	_create_panel()
	_panel.visible = shown
	if not sheet.is_empty():
		_panel.open_sheet.call_deferred(sheet)


## Язык — и в «Настройках редактора»: там его ищут в первую очередь.
func _register_language_setting() -> void:
	var es := EditorInterface.get_editor_settings()
	if not es.has_setting(GdeI18n.SETTING):
		es.set_setting(GdeI18n.SETTING, GdeI18n.language())
	es.set_initial_value(GdeI18n.SETTING, GdeI18n.DEFAULT, false)
	es.add_property_info({
		"name": GdeI18n.SETTING,
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": ",".join(GdeI18n.LANGUAGES),
	})


## Язык сменили в «Настройках редактора».
func _on_editor_settings_changed() -> void:
	var es := EditorInterface.get_editor_settings()
	if not es.has_setting(GdeI18n.SETTING):
		return
	var code := str(es.get_setting(GdeI18n.SETTING))
	if GdeI18n.LANGUAGES.has(code) and code != GdeI18n.language():
		_apply_language(code)


func _has_main_screen() -> bool:
	return true


func _get_plugin_name() -> String:
	return GdeI18n.t("События")


func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("Script", "EditorIcons")


func _make_visible(visible: bool) -> void:
	if is_instance_valid(_panel):
		_panel.visible = visible
		if visible:
			_panel.refresh_sheet_list()
			# Пока вкладка была скрыта, сцены могли поменять в редакторе сцен.
			GdeSceneCheck.invalidate()
			_panel.check_objects()


## Редактор зовёт это перед запуском игры. Раньше тут ничего не было, и
## забытая кнопка «Собрать» означала, что игра идёт по старому коду — самая
## обидная из возможных ошибок, потому что она молчит. Теперь лист сам
## сохраняется и пересобирается, а неудачная сборка не пускает игру дальше:
## лучше увидеть ошибку в консоли, чем гадать, почему событие не сработало.
func _build() -> bool:
	# Игра, запущенная из редактора, пишет свои предупреждения на том же языке.
	GdeI18n.write_runtime_language()
	if is_instance_valid(_panel):
		_panel.save_if_dirty()
	var report := GdeBuild.build_all()
	if report["failed"] > 0:
		for line: String in report["log"]:
			print(line)
		push_error(GdeI18n.t("GDevents: листы событий не собираются (%d шт.) — игра запущена не будет. Подробности выше.")
				% report["failed"])
		if is_instance_valid(_panel):
			_panel.report_build_failure(report)
		return false
	return true


## Зовётся при Ctrl+S в редакторе. Лист — такие же данные, как сцена,
## и сохраняться должен тем же движением.
func _save_external_data() -> void:
	if is_instance_valid(_panel):
		_panel.save_if_dirty()


func _rebuild() -> void:
	var report := GdeBuild.build_all()
	for line: String in report["log"]:
		print(line)
	if report["failed"] > 0:
		push_error(GdeI18n.t("GDevents: сборка не удалась для %d листа(ов)") % report["failed"])
	else:
		print(GdeI18n.t("GDevents: собрано листов — %d") % report["ok"])
	EditorInterface.get_resource_filesystem().scan()
