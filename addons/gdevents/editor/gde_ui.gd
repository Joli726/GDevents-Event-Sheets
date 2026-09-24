## Мелкие помощники для окон редактора.
@tool
class_name GdeUi
extends RefCounted

const MIN_SIZE := Vector2i(420, 320)


## Показать диалог заданного размера, гарантированно влезающего в экран.
##
## AcceptDialog сам раздувается по минимальному размеру содержимого и легко
## вылезает за края. popup_centered_clamped этого не удерживает, поэтому
## размер выставляется явно и ещё раз после того, как Godot пересчитал вёрстку.
static func popup_fit(win: Window, want: Vector2i) -> void:
	var host := _host_rect(win)
	var sz := Vector2i(
			clampi(want.x, MIN_SIZE.x, int(host.size.x * 0.92)),
			clampi(want.y, MIN_SIZE.y, int(host.size.y * 0.92)))

	win.min_size = MIN_SIZE
	win.max_size = host.size
	win.unresizable = false
	win.set_meta("gde_fit_size", sz)
	win.popup_centered(sz)
	_place(win, sz, host)

	# Контейнеры пересчитывают минимумы не мгновенно: только что заполненный
	# список успевает на кадр-другой заявить минимум во весь свой текст, и
	# окно раздувается на всю высоту экрана. Одного повторного выставления
	# мало — переставляем несколько кадров подряд, пока вёрстка не устаканится.
	var tree := win.get_tree()
	if tree == null:
		return
	for _i in range(4):
		await tree.process_frame
		if not is_instance_valid(win) or not win.visible:
			return
		_place(win, sz, _host_rect(win))


## Вернуть окну размер, с которым его открыли. Нужно, когда содержимое
## поменялось уже в открытом окне: текст с переносом на кадр получает
## нулевую ширину, заявляет огромную высоту, окно растёт — а обратно
## само не сжимается, и кнопки уезжают за край экрана.
static func refit(win: Window) -> void:
	if not win.has_meta("gde_fit_size"):
		return
	var sz: Vector2i = win.get_meta("gde_fit_size")
	var tree := win.get_tree()
	if tree == null:
		return
	for _i in range(4):
		await tree.process_frame
		if not is_instance_valid(win) or not win.visible:
			return
		if win.size != sz:
			_place(win, sz, _host_rect(win))


static func _place(win: Window, sz: Vector2i, host: Rect2i) -> void:
	win.size = sz
	win.position = host.position + (host.size - sz) / 2


## Куда вписывать окно. Редактор Godot по умолчанию встраивает подокна
## внутрь главного окна — тогда координаты отсчитываются от него, а не от
## экрана, и центрирование по монитору увело бы диалог за край.
static func _host_rect(win: Window) -> Rect2i:
	var n: Node = win.get_parent()
	while n != null:
		if n is Window:
			var host := n as Window
			if host.gui_embed_subwindows:
				return Rect2i(Vector2i.ZERO, host.size)
			break
		n = n.get_parent()
	var screen := win.current_screen
	if screen < 0:
		screen = DisplayServer.window_get_current_screen()
	return DisplayServer.screen_get_usable_rect(screen)
