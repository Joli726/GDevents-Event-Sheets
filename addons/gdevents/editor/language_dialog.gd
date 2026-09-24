## Выбор языка при первом запуске плагина. Текст — сразу на всех языках:
## какой из них человек читает, ещё неизвестно.
@tool
class_name GdeLanguageDialog
extends AcceptDialog

## Язык выбран. Закрыли окно, не выбрав, — остаётся язык по умолчанию.
signal chosen(code: String)

var _pick: OptionButton


func _init() -> void:
	title = "GDevents"
	ok_button_text = "OK"
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	var text := Label.new()
	text.custom_minimum_size = Vector2(500, 0)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.text = "Choose the plugin language. You can change it any time on the Events panel or in Editor Settings → GDevents.\n\nВыберите язык плагина. Сменить его можно в любой момент на панели «События» или в Настройках редактора → GDevents."  # i18n: как есть
	box.add_child(text)
	_pick = OptionButton.new()
	for i in range(GdeI18n.LANGUAGES.size()):
		_pick.add_item(str(GdeI18n.NAMES[GdeI18n.LANGUAGES[i]]), i)
	_pick.select(GdeI18n.LANGUAGES.find(GdeI18n.DEFAULT))
	box.add_child(_pick)
	confirmed.connect(func() -> void: chosen.emit(selected()))
	canceled.connect(func() -> void: chosen.emit(GdeI18n.DEFAULT))


func ask() -> void:
	GdeUi.popup_fit(self, Vector2i(560, 240))
	_pick.grab_focus()


func selected() -> String:
	return GdeI18n.LANGUAGES[maxi(0, _pick.selected)]
