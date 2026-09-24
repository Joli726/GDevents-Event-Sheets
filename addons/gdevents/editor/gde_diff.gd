## Построчное сравнение двух текстов — что изменено в своей копии поведения
## относительно встроенной и что изменилось во встроенной после обновления.
##
## Наибольшая общая подпоследовательность строк. Скрипты поведений — сотни
## строк, так что простой таблицы хватает с запасом, а общее начало и конец
## отрезаются заранее: обычно правка — пара мест посреди файла.
@tool
class_name GdeDiff
extends RefCounted


## [[" ", строка], ["-", строка], ["+", строка], ...] — как превратить a в b.
static func lines(a: String, b: String) -> Array:
	var la := a.split("\n")
	var lb := b.split("\n")
	var head := 0
	while head < la.size() and head < lb.size() and la[head] == lb[head]:
		head += 1
	var tail := 0
	while tail < la.size() - head and tail < lb.size() - head \
			and la[la.size() - 1 - tail] == lb[lb.size() - 1 - tail]:
		tail += 1

	var out: Array = []
	for i in range(head):
		out.append([" ", la[i]])
	var ma := la.slice(head, la.size() - tail)
	var mb := lb.slice(head, lb.size() - tail)
	out.append_array(_lcs(ma, mb))
	for i in range(la.size() - tail, la.size()):
		out.append([" ", la[i]])
	return out


static func _lcs(a: PackedStringArray, b: PackedStringArray) -> Array:
	var n := a.size()
	var m := b.size()
	# t[i][j] — длина общей части a[i:] и b[j:], в одном плоском массиве.
	var w := m + 1
	var t := PackedInt32Array()
	t.resize((n + 1) * w)
	for i in range(n - 1, -1, -1):
		for j in range(m - 1, -1, -1):
			if a[i] == b[j]:
				t[i * w + j] = t[(i + 1) * w + j + 1] + 1
			else:
				t[i * w + j] = maxi(t[(i + 1) * w + j], t[i * w + j + 1])
	var out: Array = []
	var i := 0
	var j := 0
	while i < n and j < m:
		if a[i] == b[j]:
			out.append([" ", a[i]])
			i += 1
			j += 1
		elif t[(i + 1) * w + j] >= t[i * w + j + 1]:
			out.append(["-", a[i]])
			i += 1
		else:
			out.append(["+", b[j]])
			j += 1
	while i < n:
		out.append(["-", a[i]])
		i += 1
	while j < m:
		out.append(["+", b[j]])
		j += 1
	return out


static func stats(ops: Array) -> Dictionary:
	var added := 0
	var removed := 0
	for op: Array in ops:
		if op[0] == "+":
			added += 1
		elif op[0] == "-":
			removed += 1
	return {"added": added, "removed": removed}


## Только изменённые места с парой строк вокруг; остальное свёрнуто в
## [["…", "N строк без изменений"]].
static func hunks(ops: Array, context: int = 3) -> Array:
	var keep := PackedByteArray()
	keep.resize(ops.size())
	for i in range(ops.size()):
		if (ops[i] as Array)[0] != " ":
			for k in range(maxi(0, i - context), mini(ops.size(), i + context + 1)):
				keep[k] = 1
	var out: Array = []
	var skipped := 0
	for i in range(ops.size()):
		if keep[i] == 1:
			if skipped > 0:
				out.append(["…", GdeI18n.t("%d строк без изменений") % skipped])
				skipped = 0
			out.append(ops[i])
		else:
			skipped += 1
	if skipped > 0:
		out.append(["…", GdeI18n.t("%d строк без изменений") % skipped])
	return out
