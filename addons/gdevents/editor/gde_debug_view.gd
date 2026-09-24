## Вкладка «GDevents» в отладчике Godot: переменные игры вживую и сколько
## раз срабатывали события листов.
@tool
class_name GdeDebugView
extends VBoxContainer

var _tree: Tree
var _info: Label
## Сколько раз сработало каждое событие с начала игры: "лист|путь" -> раз.
var _totals: Dictionary = {}


func _init() -> void:
	_info = Label.new()
	_info.text = GdeI18n.t("Запустите игру: здесь появятся переменные и сработавшие события.")
	_info.modulate = Color(1, 1, 1, 0.7)
	add_child(_info)
	_tree = Tree.new()
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.columns = 2
	_tree.hide_root = true
	_tree.set_column_expand_ratio(0, 2)
	_tree.set_column_title(0, GdeI18n.t("Имя"))
	_tree.set_column_title(1, GdeI18n.t("Значение"))
	_tree.column_titles_visible = true
	add_child(_tree)


func show_state(st: Dictionary) -> void:
	var hits: Dictionary = st.get("hits", {})
	for sheet: String in hits:
		for pair: Variant in hits[sheet]:
			if pair is Array and (pair as Array).size() == 2:
				var key := "%s|%s" % [sheet, str(pair[0])]
				_totals[key] = int(_totals.get(key, 0)) + int(pair[1])
	_info.text = GdeI18n.t("Игра идёт. Сработавшие события подсвечены в листе на вкладке «События».")
	_tree.clear()
	var root := _tree.create_item()
	_section(root, GdeI18n.t("Переменные сцены"), st.get("scene", {}))
	_section(root, GdeI18n.t("Глобальные переменные"), st.get("global", {}))
	var ev := _tree.create_item(root)
	ev.set_text(0, GdeI18n.t("Срабатывания событий"))
	var keys := _totals.keys()
	keys.sort()
	for k: String in keys:
		var it := _tree.create_item(ev)
		var parts := k.split("|")
		it.set_text(0, GdeI18n.t("%s, событие %s") % [parts[0].get_file(), _human_path(parts[1])])
		it.set_text(1, str(_totals[k]))


func _section(root: TreeItem, title: String, vars: Variant) -> void:
	var head := _tree.create_item(root)
	head.set_text(0, title)
	if vars is Dictionary:
		_fill(head, vars)


func _fill(parent: TreeItem, d: Dictionary) -> void:
	var keys := d.keys()
	keys.sort()
	for k: Variant in keys:
		var it := _tree.create_item(parent)
		it.set_text(0, str(k))
		var v: Variant = d[k]
		if v is Dictionary:
			_fill(it, v)
		else:
			it.set_text(1, str(GdeSheetDocument._normalize(v)))


## [2, 0] → «3.1»: люди считают события с единицы.
static func _human_path(p: String) -> String:
	var parsed: Variant = JSON.parse_string(p)
	if not (parsed is Array):
		return p
	var parts: Array[String] = []
	for x: Variant in parsed:
		parts.append(str(int(x) + 1))
	return ".".join(parts)
