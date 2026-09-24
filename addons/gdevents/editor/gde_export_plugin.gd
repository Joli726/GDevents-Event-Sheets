## Экспорт игры: листы собираются заново.
##
## Перед запуском из редактора листы пересобираются сами, а перед экспортом
## раньше — нет: забытая кнопка «Собрать» означала, что в готовую игру уходит
## старый код, и заметить это можно было только у игрока.
@tool
class_name GdeExportPlugin
extends EditorExportPlugin

## Панель — чтобы сохранить несохранённую правку листа перед сборкой.
var panel: Node = null
## Итог последней сборки — для теста и для сообщения в конце экспорта.
var last_report: Dictionary = {}


func _get_name() -> String:
	return "GDevents"


func _export_begin(_features: PackedStringArray, _is_debug: bool, _path: String, _flags: int) -> void:
	if is_instance_valid(panel) and panel.has_method("save_if_dirty"):
		panel.call("save_if_dirty")
	last_report = GdeBuild.build_all()
	if int(last_report["failed"]) > 0:
		for line: String in last_report["log"]:
			print(line)
		# Прервать экспорт Godot не даёт — остаётся сказать громко.
		push_error(GdeI18n.t("GDevents: листы событий не собираются (%d шт.) — в экспортированной игре останется их старый код. Подробности выше.")
				% last_report["failed"])
	else:
		print(GdeI18n.t("GDevents: листы собраны перед экспортом — %d") % last_report["ok"])
