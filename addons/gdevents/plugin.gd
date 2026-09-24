@tool
extends EditorPlugin

const AUTOLOAD_NAME := "Gde"
const AUTOLOAD_PATH := "res://addons/gdevents/runtime/gde_runtime.gd"
const MENU_ITEM := "GDevents: пересобрать листы событий"


var _panel: GdeEventSheetPanel


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
	add_tool_menu_item(MENU_ITEM, _rebuild)

	_panel = GdeEventSheetPanel.new()
	_panel.name = "GDevents"
	# Главный экран редактора — контейнер, и он игнорирует якоря: без флагов
	# растяжения панель схлопывается по высоте тулбара, а список событий
	# обрезается в ноль. Якоря оставлены на случай не-контейнерного родителя.
	_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	EditorInterface.get_editor_main_screen().add_child(_panel)
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.hide()


func _exit_tree() -> void:
	remove_tool_menu_item(MENU_ITEM)
	if is_instance_valid(_panel):
		_panel.queue_free()
	_panel = null


func _has_main_screen() -> bool:
	return true


func _get_plugin_name() -> String:
	return "События"


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
	if is_instance_valid(_panel):
		_panel.save_if_dirty()
	var report := GdeBuild.build_all()
	if report["failed"] > 0:
		for line: String in report["log"]:
			print(line)
		push_error("GDevents: листы событий не собираются (%d шт.) — игра запущена не будет. Подробности выше."
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
		push_error("GDevents: сборка не удалась для %d листа(ов)" % report["failed"])
	else:
		print("GDevents: собрано листов — %d" % report["ok"])
	EditorInterface.get_resource_filesystem().scan()
