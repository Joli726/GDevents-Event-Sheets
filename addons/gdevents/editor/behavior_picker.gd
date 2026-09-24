## Выбор поведения для объекта — аналог «Добавить поведение» в GDevelop.
@tool
class_name GdeBehaviorPicker
extends ConfirmationDialog

signal picked(behavior_name: String, script_path: String)

var _list: ItemList
var _desc: RichTextLabel
var _entries: Array = []


func _init() -> void:
	title = GdeI18n.t("Добавить поведение")
	ok_button_text = GdeI18n.t("Добавить")
	cancel_button_text = GdeI18n.t("Отмена")

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)

	var hint := Label.new()
	hint.text = GdeI18n.t("Поведение станет дочерней нодой в сцене объекта, а его настройки откроются в окне объекта.")
	hint.clip_text = true
	hint.add_theme_font_size_override("font_size", 11)
	hint.modulate = Color(1, 1, 1, 0.6)
	box.add_child(hint)

	_list = ItemList.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.custom_minimum_size = Vector2(0, 260)
	_list.item_selected.connect(_on_selected)
	_list.item_activated.connect(func(_i):
		_emit()
		hide())
	box.add_child(_list)

	_desc = RichTextLabel.new()
	_desc.bbcode_enabled = true
	_desc.fit_content = true
	_desc.scroll_active = false
	_desc.custom_minimum_size = Vector2(0, 60)
	box.add_child(_desc)

	confirmed.connect(_emit)


func open_for(reg: GdeRegistry, already: Array) -> void:
	_entries.clear()
	_list.clear()
	for bname: String in reg.behaviors:
		var b: Dictionary = reg.behaviors[bname]
		if already.has(bname):
			continue
		_entries.append({"name": bname, "def": b})
	_entries.sort_custom(func(a, b): return str(a["name"]) < str(b["name"]))

	for e: Dictionary in _entries:
		var b: Dictionary = e["def"]
		var idx := _list.add_item(str(b.get("title", e["name"])),
				GdeIcons.get_icon(str(b.get("icon", "behavior"))))
		_list.set_item_tooltip(idx, str(b.get("description", "")))

	if _list.item_count == 0:
		_desc.text = GdeI18n.t("[color=#c98a8a]Все доступные поведения уже добавлены этому объекту.[/color]")
		get_ok_button().disabled = true
	else:
		get_ok_button().disabled = false
		_list.select(0)
		_on_selected(0)
	GdeUi.popup_fit(self, Vector2i(660, 520))


func _on_selected(idx: int) -> void:
	if idx < 0 or idx >= _entries.size():
		return
	var e: Dictionary = _entries[idx]
	var b: Dictionary = e["def"]
	var desc := str(b.get("description", GdeI18n.t("Без описания.")))
	var props: Dictionary = b.get("properties", {})
	var acts: Dictionary = b.get("actions", {})
	var conds: Dictionary = b.get("conditions", {})
	var text := GdeI18n.t("[b]%s[/b]\n[color=#9aa0a6]%s[/color]\n[color=#7f868c]Свойств: %d · действий: %d · условий: %d[/color]") \
			% [str(b.get("title", e["name"])), desc, props.size(), acts.size(), conds.size()]
	var scaffold := _scaffold_note(b)
	if not scaffold.is_empty():
		text += "\n[color=#8fbf8f]%s[/color]" % scaffold
	_desc.text = text


## Что поведение достроит в сцене. Сказать об этом надо заранее: молча
## менять чужую сцену нельзя, а узнать постфактум — неприятный сюрприз.
func _scaffold_note(b: Dictionary) -> String:
	var bits: Array[String] = []
	var target := str(b.get("target", ""))
	if not target.is_empty():
		bits.append(target)
	for n: Variant in b.get("needs", []):
		bits.append(str((n as Dictionary).get("name", "")))
	if bits.is_empty():
		return ""
	return GdeI18n.t("Если в сцене этого нет, будет создано: %s") % ", ".join(bits)


func _emit() -> void:
	var sel := _list.get_selected_items()
	if sel.is_empty():
		return
	var e: Dictionary = _entries[sel[0]]
	var b: Dictionary = e["def"]
	picked.emit(str(e["name"]), str(b.get("path", "")))
