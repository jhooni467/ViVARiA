extends Node2D

const TITLES := ["Semillas en orden", "Parejas del bosque", "Un camino de agua", "El rincón de las hojas", "Un jardín en equilibrio"]
const DESCRIPTIONS := [
	"Coloca las cuatro semillas de la más pequeña a la más grande.",
	"Encuentra las tres parejas de símbolos escondidos.",
	"Gira las tuberías para llevar el agua hasta la flor.",
	"Cada hoja quiere volver a su maceta del mismo color.",
	"Completa el lado derecho para reflejar el pequeño jardín."
]
const HINTS := [
	"Selecciona una semilla y luego otra para intercambiar sus lugares.",
	"Recuerda los símbolos que vas descubriendo. Hay tres parejas.",
	"El agua sale por la izquierda, baja, cruza y vuelve a subir.",
	"Selecciona una hoja y después toca la maceta de su color.",
	"El lado derecho debe ser el reflejo exacto del lado izquierdo."
]
const ACCENTS := [Color("#b6c98b"), Color("#d9b9a2"), Color("#8ac9c2"), Color("#e5c77c"), Color("#b9a9d4")]
const PANEL := Color("#faf9f0")
const INK := Color("#3e5743")
const MUTED := Color("#829078")
const GREEN := Color("#789d70")
const DARK_GREEN := Color("#527a5a")

var _layer: CanvasLayer
var _root: Control
var _screen := "home"
var _level := 1
var _completed: Array[int] = []
var _status: Label
var _board: Control

var _seeds: Array[int] = [3, 1, 4, 2]
var _selected_seed := -1
var _memory_faces: Array[String] = ["✿", "❧", "◈", "◈", "✿", "❧"]
var _memory_open: Array[int] = []
var _memory_pairs: Array[int] = []
var _pipes: Array[int] = [0, 1, 3, 1, 2]
var _leaf_items: Array[int] = [2, 0, 1]
var _leaf_pots: Array[int] = [-1, -1, -1]
var _selected_leaf := -1
var _mirror_fixed: Array[int] = [0, 5, 8, 13]
var _mirror_targets: Array[int] = [3, 6, 11, 14]
var _mirror_filled: Array[int] = []


func _ready() -> void:
	randomize()
	_load_progress()
	_layer = CanvasLayer.new()
	_layer.name = "Interface"
	add_child(_layer)
	_show_home()
	queue_redraw()


func _draw() -> void:
	var s := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, s), Color("#eaf0d8"), true)
	draw_colored_polygon(PackedVector2Array([Vector2(0,0), Vector2(210,0), Vector2(440,125), Vector2(700,0), Vector2(1010,110), Vector2(s.x,0), Vector2(s.x,s.y), Vector2(0,s.y)]), Color("#e3edce"))
	draw_colored_polygon(PackedVector2Array([Vector2(0,280), Vector2(190,205), Vector2(390,300), Vector2(590,205), Vector2(820,310), Vector2(1030,220), Vector2(s.x,300), Vector2(s.x,s.y), Vector2(0,s.y)]), Color("#d1e4b5"))
	draw_colored_polygon(PackedVector2Array([Vector2(0,460), Vector2(230,390), Vector2(460,470), Vector2(710,370), Vector2(930,470), Vector2(1140,390), Vector2(s.x,470), Vector2(s.x,s.y), Vector2(0,s.y)]), Color("#c1dba1"))
	_tree(Vector2(78,110), 0.72, Color("#75a779"))
	_tree(Vector2(s.x-95,134), 0.82, Color("#80ad77"))
	_tree(Vector2(205,s.y-36), 0.60, Color("#8ab37a"))
	_tree(Vector2(s.x-230,s.y-24), 0.62, Color("#8caf7b"))
	_flower(Vector2(330,110))
	_flower(Vector2(s.x-390,s.y-86))


func _tree(p: Vector2, k: float, c: Color) -> void:
	draw_rect(Rect2(p+Vector2(-5*k,8*k),Vector2(10*k,32*k)),Color("#986c51"))
	draw_circle(p+Vector2(0,-8*k),24*k,c)
	draw_circle(p+Vector2(-16*k,2*k),16*k,c.lightened(0.06))
	draw_circle(p+Vector2(16*k,2*k),16*k,c.darkened(0.04))
	draw_circle(p+Vector2(4*k,-23*k),12*k,c.lightened(0.1))
	draw_circle(p+Vector2(7*k,-12*k),3*k,Color("#d6e49d"))


func _flower(p: Vector2) -> void:
	draw_line(p,p+Vector2(0,-15),Color("#729a69"),2.5,true)
	draw_circle(p+Vector2(0,-18),5,Color("#efb2a1"))
	draw_circle(p+Vector2(-5,-18),4,Color("#efb2a1"))
	draw_circle(p+Vector2(5,-18),4,Color("#efb2a1"))
	draw_circle(p+Vector2(0,-18),2,Color("#f5d77c"))


func _load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load("user://vivaria_progress.cfg") != OK:
		return
	var saved: Variant = cfg.get_value("classic","completed",[])
	if saved is Array:
		for value in saved:
			var n := int(value)
			if n >= 1 and n <= 5 and not _completed.has(n):
				_completed.append(n)


func _save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("classic","completed",_completed)
	cfg.save("user://vivaria_progress.cfg")


func _page() -> Control:
	for child in _layer.get_children():
		child.queue_free()
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_PASS
	_layer.add_child(_root)
	_status = null
	_board = null
	return _root


func _panel(parent: Control, pos: Vector2, size: Vector2, color: Color = PANEL, radius: int = 24) -> PanelContainer:
	var p := PanelContainer.new()
	p.position = pos
	p.size = size
	p.custom_minimum_size = size
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("#ffffff")
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.18,0.25,0.16,0.12)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0,4)
	p.add_theme_stylebox_override("panel",style)
	parent.add_child(p)
	return p


func _margin(parent: Control, l: int = 22, t: int = 20, r: int = 22, b: int = 20) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left",l)
	m.add_theme_constant_override("margin_top",t)
	m.add_theme_constant_override("margin_right",r)
	m.add_theme_constant_override("margin_bottom",b)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(m)
	return m


func _label(parent: Control, text_value: String, size: int, color: Color = INK, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text_value
	l.add_theme_font_size_override("font_size",size)
	l.add_theme_color_override("font_color",color)
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(l)
	return l


func _button(parent: Control, text_value: String, size: Vector2, callback: Callable, color: Color = GREEN, font_size: int = 14) -> Button:
	var b := Button.new()
	b.text = text_value
	b.custom_minimum_size = size
	b.size = size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size",font_size)
	b.add_theme_color_override("font_color",Color("#ffffff"))
	b.add_theme_color_override("font_hover_color",Color("#ffffff"))
	b.add_theme_color_override("font_pressed_color",Color("#ffffff"))
	var normal := StyleBoxFlat.new()
	normal.bg_color = color
	normal.border_color = color.lightened(0.16)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(17)
	b.add_theme_stylebox_override("normal",normal)
	var hover := StyleBoxFlat.new()
	hover.bg_color = color.lightened(0.08)
	hover.set_border_width_all(1)
	hover.set_border_color(color.lightened(0.2))
	hover.set_corner_radius_all(17)
	b.add_theme_stylebox_override("hover",hover)
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = color.darkened(0.08)
	pressed.set_corner_radius_all(17)
	b.add_theme_stylebox_override("pressed",pressed)
	b.pressed.connect(callback)
	parent.add_child(b)
	return b


func _soft_button(parent: Control, text_value: String, size: Vector2, callback: Callable) -> Button:
	var b := Button.new()
	b.text = text_value
	b.custom_minimum_size = size
	b.size = size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size",13)
	b.add_theme_color_override("font_color",INK)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#edf0e2")
	normal.border_color = Color("#e1e7d6")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(16)
	b.add_theme_stylebox_override("normal",normal)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color("#e2ebd6")
	hover.set_corner_radius_all(16)
	b.add_theme_stylebox_override("hover",hover)
	b.add_theme_stylebox_override("pressed",hover)
	b.pressed.connect(callback)
	parent.add_child(b)
	return b


func _animate(node: Control) -> void:
	node.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(node,"modulate:a",1.0,0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _show_home() -> void:
	_screen = "home"
	var root := _page()
	var brand := _panel(root,Vector2(48,24),Vector2(390,76),PANEL,22)
	var bm := _margin(brand,18,7,18,7)
	var bs := VBoxContainer.new()
	bs.add_theme_constant_override("separation",0)
	bm.add_child(bs)
	_label(bs,"ViVARiA",27,INK)
	_label(bs,"UN PEQUEÑO MUNDO DE RETOS",10,MUTED)

	var chip := _panel(root,Vector2(900,30),Vector2(330,58),Color("#f1f4e7"),20)
	_label(_margin(chip,12,4,12,4),"MODO CLÁSICO  ·  5 DESAFÍOS",13,DARK_GREEN,HORIZONTAL_ALIGNMENT_CENTER)

	var hero := _panel(root,Vector2(48,126),Vector2(1184,548),PANEL,30)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation",34)
	_margin(hero,38,34,38,34).add_child(columns)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(580,0)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation",12)
	columns.add_child(left)
	_label(left,"BIENVENIDO A TU ESPACIO",11,MUTED)
	var headline := _label(left,"Pequeños retos.\nGrandes momentos.",37,INK)
	headline.custom_minimum_size = Vector2(0,112)
	headline.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label(left,"Resuelve, ordena y descubre a tu ritmo.\nSin prisa. Solo un reto bonito a la vez.",17,MUTED)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0,12)
	left.add_child(spacer)
	_button(left,"CONTINUAR  →",Vector2(250,64),_start_next,DARK_GREEN,16).size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_soft_button(left,"VER TODOS LOS NIVELES",Vector2(250,54),_show_levels).size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var note := _label(left,"5 RETOS CORTOS  ·  PROGRESO GUARDADO EN TU DISPOSITIVO",10,MUTED)
	note.custom_minimum_size = Vector2(0,38)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var preview := _panel(columns,Vector2.ZERO,Vector2(420,430),Color("#edf2e3"),26)
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ps := VBoxContainer.new()
	ps.add_theme_constant_override("separation",10)
	_margin(preview,24,22,24,20).add_child(ps)
	_label(ps,"TU CAMINO",12,MUTED)
	_label(ps,"Modo clásico",24,INK)
	_label(ps,"%d de 5 desafíos completados" % _completed.size(),13,MUTED)
	var progress_bg := _panel(ps,Vector2.ZERO,Vector2(0,14),Color("#dce5d1"),9)
	progress_bg.custom_minimum_size = Vector2(0,14)
	var progress_fill := ColorRect.new()
	progress_fill.color = Color("#8eae7d")
	progress_fill.size = Vector2(348.0 * float(_completed.size()) / 5.0,14)
	progress_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_bg.add_child(progress_fill)
	var divider := HSeparator.new()
	divider.add_theme_color_override("color",Color("#dce5d5"))
	ps.add_child(divider)
	var next := _next_level()
	var next_card := _panel(ps,Vector2.ZERO,Vector2(0,142),PANEL,20)
	next_card.custom_minimum_size = Vector2(0,142)
	var ns := VBoxContainer.new()
	ns.add_theme_constant_override("separation",5)
	_margin(next_card,17,14,17,12).add_child(ns)
	_label(ns,"SIGUIENTE DESAFÍO",10,MUTED)
	var next_title := _label(ns,"%02d  ·  %s" % [next,TITLES[next-1]],17,INK)
	next_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var next_desc := _label(ns,DESCRIPTIONS[next-1],12,MUTED)
	next_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label(ps,"PEQUEÑOS PASOS, GRANDES SONRISAS.",10,DARK_GREEN)
	_animate(hero)


func _show_levels() -> void:
	_screen = "levels"
	var root := _page()
	var back := _soft_button(root,"← VOLVER",Vector2(126,54),_show_home)
	back.position = Vector2(46,30)
	var h := _label(root,"Modo clásico",30,INK)
	h.position = Vector2(198,25)
	h.size = Vector2(440,42)
	var sub := _label(root,"Cinco pequeños desafíos para empezar.",13,MUTED)
	sub.position = Vector2(200,68)
	sub.size = Vector2(450,26)
	var counter := _label(root,"%d / 5 COMPLETADOS" % _completed.size(),12,DARK_GREEN,HORIZONTAL_ALIGNMENT_RIGHT)
	counter.position = Vector2(900,35)
	counter.size = Vector2(320,32)

	var w := 216.0
	var gap := 14.0
	var x0 := (1280.0-(w*5.0+gap*4.0))*0.5
	for i in range(5):
		var n := i+1
		var unlocked := _unlocked(n)
		var done := _completed.has(n)
		var card := _panel(root,Vector2(x0+float(i)*(w+gap),145),Vector2(w,470),PANEL if unlocked else Color("#f0f0e6"),25)
		var stack := VBoxContainer.new()
		stack.add_theme_constant_override("separation",9)
		_margin(card,17,19,17,17).add_child(stack)

		var num := _panel(stack,Vector2.ZERO,Vector2(64,54),ACCENTS[i].lightened(0.24) if unlocked else Color("#e4e5dc"),16)
		num.custom_minimum_size = Vector2(64,54)
		_label(_margin(num,4,2,4,2),"%02d" % n,21,INK,HORIZONTAL_ALIGNMENT_CENTER)
		_label(stack,["OBSERVA","RECUERDA","CONECTA","CLASIFICA","COMPLETA"][i],10,MUTED)
		var title := _label(stack,TITLES[i],18,INK if unlocked else MUTED)
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title.custom_minimum_size = Vector2(0,65)
		var desc := _label(stack,DESCRIPTIONS[i],12,MUTED)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.custom_minimum_size = Vector2(0,104)
		var fill := Control.new()
		fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
		stack.add_child(fill)
		_label(stack,"✓ COMPLETADO" if done else ("DISPONIBLE" if unlocked else "BLOQUEADO"),10,DARK_GREEN if unlocked else MUTED)
		var play := _button(stack,"JUGAR" if unlocked else "CERRADO",Vector2(0,48),_open_level.bind(n),DARK_GREEN if unlocked else Color("#b8bdae"),12)
		play.disabled = not unlocked
		play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_animate(root)


func _show_game() -> void:
	_screen = "game"
	var root := _page()
	var back := _soft_button(root,"← NIVELES",Vector2(136,54),_show_levels)
	back.position = Vector2(46,25)
	var heading := _label(root,"NIVEL %02d  ·  %s" % [_level,TITLES[_level-1].to_upper()],18,INK)
	heading.position = Vector2(208,30)
	heading.size = Vector2(670,38)
	var count := _label(root,"%d / 5" % _level,14,MUTED,HORIZONTAL_ALIGNMENT_RIGHT)
	count.position = Vector2(1060,31)
	count.size = Vector2(160,34)

	var info := _panel(root,Vector2(46,112),Vector2(300,560),PANEL,25)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation",9)
	_margin(info,22,20,22,20).add_child(stack)
	_label(stack,"DESAFÍO %02d" % _level,10,MUTED)
	var title := _label(stack,TITLES[_level-1],23,INK)
	title.custom_minimum_size = Vector2(0,62)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var desc := _label(stack,DESCRIPTIONS[_level-1],14,MUTED)
	desc.custom_minimum_size = Vector2(0,98)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var how := _panel(stack,Vector2.ZERO,Vector2(0,92),Color("#eff3e7"),17)
	how.custom_minimum_size = Vector2(0,92)
	var how_stack := VBoxContainer.new()
	how_stack.add_theme_constant_override("separation",3)
	_margin(how,13,9,13,9).add_child(how_stack)
	_label(how_stack,"CÓMO JUGAR",9,DARK_GREEN)
	var how_text: String = ["Toca una semilla y luego otra para cambiar sus posiciones.","Toca dos tarjetas. Si son iguales, se quedarán descubiertas.","Toca las piezas curvas para girarlas y unir el recorrido.","Elige una hoja y después la maceta que tenga su color.","Toca los espacios vacíos para dibujar el reflejo."][_level-1]
	var how_label := _label(how_stack,how_text,12,MUTED)
	how_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var grow := Control.new()
	grow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(grow)
	_status = _label(stack,"Tómate tu tiempo. No hay prisa.",12,MUTED)
	_status.custom_minimum_size = Vector2(0,52)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_soft_button(stack,"VER PISTA",Vector2(0,48),_show_hint).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_button(stack,"COMPROBAR",Vector2(0,56),_check,DARK_GREEN,14).size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var board_panel := _panel(root,Vector2(370,112),Vector2(864,560),PANEL,25)
	var board_stack := VBoxContainer.new()
	board_stack.add_theme_constant_override("separation",6)
	_margin(board_panel,25,22,25,22).add_child(board_stack)
	_label(board_stack,"TU ESPACIO DE JUEGO",10,MUTED)
	var line := HSeparator.new()
	line.add_theme_color_override("color",Color("#e8eadf"))
	board_stack.add_child(line)
	_board = Control.new()
	_board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board_stack.add_child(_board)
	_render_board()
	_animate(board_panel)


func _render_board() -> void:
	if not is_instance_valid(_board):
		return
	for child in _board.get_children():
		child.queue_free()
	match _level:
		1: _build_seeds()
		2: _build_memory()
		3: _build_pipes()
		4: _build_leaves()
		5: _build_mirror()


func _tile_style(b: Button, color: Color, selected: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = color.darkened(0.04) if selected else color
	normal.border_color = Color("#8eae7d") if selected else Color("#ffffff")
	normal.set_border_width_all(2 if selected else 1)
	normal.set_corner_radius_all(20)
	b.add_theme_stylebox_override("normal",normal)
	var hover := StyleBoxFlat.new()
	hover.bg_color = color.lightened(0.06)
	hover.border_color = Color("#a9c397")
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(20)
	b.add_theme_stylebox_override("hover",hover)
	var pressed := StyleBoxFlat.new()
	pressed.bg_color = color.darkened(0.06)
	pressed.set_corner_radius_all(20)
	b.add_theme_stylebox_override("pressed",pressed)


func _build_seeds() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_board.add_child(center)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",16)
	center.add_child(row)
	var glyphs := ["·","•","●","⬤"]
	for i in range(4):
		var value: int = _seeds[i]
		var b := Button.new()
		b.custom_minimum_size = Vector2(158,220)
		b.focus_mode = Control.FOCUS_NONE
		_tile_style(b,Color("#edf2e4") if _selected_seed != i else Color("#dce9d0"),_selected_seed == i)
		b.pressed.connect(_on_seed.bind(i))
		row.add_child(b)
		var contents := VBoxContainer.new()
		contents.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
		contents.add_theme_constant_override("separation",5)
		b.add_child(contents)
		var top := Control.new()
		top.size_flags_vertical = Control.SIZE_EXPAND_FILL
		contents.add_child(top)
		var glyph := _label(contents,glyphs[value-1],26+value*9,DARK_GREEN,HORIZONTAL_ALIGNMENT_CENTER)
		glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var caption := _label(contents,"SEMILLA",11,MUTED,HORIZONTAL_ALIGNMENT_CENTER)
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var bottom := Control.new()
		bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
		contents.add_child(bottom)


func _on_seed(i: int) -> void:
	if _selected_seed == -1:
		_selected_seed = i
		_feedback("Ahora elige otra semilla para intercambiarla.")
	else:
		if _selected_seed != i:
			var temp: int = _seeds[i]
			_seeds[i] = _seeds[_selected_seed]
			_seeds[_selected_seed] = temp
			_feedback("¡Cambio hecho! Sigue ordenando las semillas.")
		_selected_seed = -1
	_render_board()


func _build_memory() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_board.add_child(center)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation",17)
	grid.add_theme_constant_override("v_separation",14)
	center.add_child(grid)
	for i in range(6):
		var visible := _memory_pairs.has(i) or _memory_open.has(i)
		var b := Button.new()
		b.custom_minimum_size = Vector2(164,142)
		b.focus_mode = Control.FOCUS_NONE
		b.text = _memory_faces[i] if visible else "?"
		b.add_theme_font_size_override("font_size",37 if visible else 30)
		b.add_theme_color_override("font_color",DARK_GREEN if visible else Color("#8aa17e"))
		_tile_style(b,Color("#e1ecd8") if _memory_pairs.has(i) else (Color("#f4eee1") if visible else Color("#edf2e4")),_memory_open.has(i))
		b.disabled = _memory_pairs.has(i)
		b.pressed.connect(_on_memory.bind(i))
		grid.add_child(b)


func _on_memory(i: int) -> void:
	if _memory_pairs.has(i) or _memory_open.has(i):
		return
	if _memory_open.size() >= 2:
		_memory_open.clear()
	_memory_open.append(i)
	if _memory_open.size() == 2:
		var a: int = _memory_open[0]
		var b: int = _memory_open[1]
		if _memory_faces[a] == _memory_faces[b]:
			_memory_pairs.append(a)
			_memory_pairs.append(b)
			_memory_open.clear()
			_feedback("¡Encontraste una pareja!")
		else:
			_feedback("No son iguales. Prueba con otras dos tarjetas.")
	_render_board()


func _build_pipes() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_board.add_child(center)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation",12)
	grid.add_theme_constant_override("v_separation",12)
	center.add_child(grid)
	var path := [3,4,7,8,5]
	for cell in range(9):
		var idx := path.find(cell)
		if idx == -1:
			var blank := PanelContainer.new()
			blank.custom_minimum_size = Vector2(132,104)
			var st := StyleBoxFlat.new()
			st.bg_color = Color("#f4f4e9")
			st.set_corner_radius_all(20)
			blank.add_theme_stylebox_override("panel",st)
			grid.add_child(blank)
		else:
			var b := Button.new()
			b.custom_minimum_size = Vector2(132,104)
			b.focus_mode = Control.FOCUS_NONE
			if idx == 0:
				b.text = "◉  →\nFUENTE"
				b.add_theme_font_size_override("font_size",18)
				_tile_style(b,Color("#dcece2"),false)
				b.disabled = true
			else:
				var glyphs := ["┐","┘","└","┌"]
				b.text = "%s\nTUBERÍA" % glyphs[_pipes[idx]]
				b.add_theme_font_size_override("font_size",25)
				_tile_style(b,Color("#e1f0eb"),true)
				b.pressed.connect(_on_pipe.bind(idx))
			grid.add_child(b)


func _on_pipe(i: int) -> void:
	_pipes[i] = (_pipes[i]+1)%4
	_feedback("La tubería giró. Busca un camino continuo.")
	_render_board()


func _build_leaves() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_board.add_child(center)
	var content := VBoxContainer.new()
	content.custom_minimum_size = Vector2(660,330)
	content.add_theme_constant_override("separation",18)
	center.add_child(content)
	_label(content,"ELIGE UNA HOJA",11,MUTED,HORIZONTAL_ALIGNMENT_CENTER)
	var leaves := HBoxContainer.new()
	leaves.alignment = BoxContainer.ALIGNMENT_CENTER
	leaves.add_theme_constant_override("separation",18)
	content.add_child(leaves)
	var names := ["VERDE","CORAL","DORADA"]
	var colors := [Color("#a8c68e"),Color("#e8aaa0"),Color("#e8cc7e")]
	for i in range(3):
		var color_id: int = _leaf_items[i]
		var b := Button.new()
		b.custom_minimum_size = Vector2(170,96)
		b.text = "❧\n%s" % names[color_id]
		b.add_theme_font_size_override("font_size",19)
		b.add_theme_color_override("font_color",INK)
		var assigned := _leaf_pots.find(i) != -1
		_tile_style(b,Color("#e1e6dc") if assigned else colors[color_id].lightened(0.18),_selected_leaf == i)
		b.disabled = assigned
		b.pressed.connect(_on_leaf.bind(i))
		leaves.add_child(b)
	_label(content,"↓  DEVUÉLVELA A SU LUGAR  ↓",10,MUTED,HORIZONTAL_ALIGNMENT_CENTER)
	var pots := HBoxContainer.new()
	pots.alignment = BoxContainer.ALIGNMENT_CENTER
	pots.add_theme_constant_override("separation",18)
	content.add_child(pots)
	for i in range(3):
		var b := Button.new()
		b.custom_minimum_size = Vector2(170,112)
		b.text = "MACETA\n%s" % names[i] if _leaf_pots[i] == -1 else "✓\n%s" % names[i]
		b.add_theme_font_size_override("font_size",15)
		b.add_theme_color_override("font_color",INK)
		_tile_style(b,colors[i].lightened(0.24),_leaf_pots[i] != -1)
		b.pressed.connect(_on_pot.bind(i))
		pots.add_child(b)


func _on_leaf(i: int) -> void:
	for pot in range(3):
		if _leaf_pots[pot] == i:
			_leaf_pots[pot] = -1
			break
	_selected_leaf = i
	_feedback("Ahora elige la maceta del mismo color.")
	_render_board()


func _on_pot(i: int) -> void:
	if _leaf_pots[i] != -1:
		_feedback("Esa maceta ya tiene su hoja.")
		return
	if _selected_leaf == -1:
		_feedback("Primero selecciona una hoja.")
		return
	if _leaf_items[_selected_leaf] != i:
		_feedback("Casi. Busca la maceta que tenga ese mismo color.")
		return
	_leaf_pots[i] = _selected_leaf
	_selected_leaf = -1
	_feedback("¡Una hoja encontró su lugar!")
	_render_board()


func _build_mirror() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_board.add_child(center)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation",10)
	grid.add_theme_constant_override("v_separation",10)
	center.add_child(grid)
	for i in range(16):
		var col := i%4
		var fixed := _mirror_fixed.has(i)
		var filled := _mirror_filled.has(i)
		var b := Button.new()
		b.custom_minimum_size = Vector2(92,86)
		b.focus_mode = Control.FOCUS_NONE
		b.text = "✿" if fixed or filled else "·"
		b.add_theme_font_size_override("font_size",27 if fixed or filled else 24)
		b.add_theme_color_override("font_color",DARK_GREEN if fixed or filled else Color("#b4c2a7"))
		_tile_style(b,Color("#e2edd8") if fixed else (Color("#dce9d0") if filled else Color("#f0f2e7")),filled)
		b.disabled = col < 2
		b.pressed.connect(_on_mirror.bind(i))
		grid.add_child(b)


func _on_mirror(i: int) -> void:
	if _mirror_filled.has(i):
		_mirror_filled.erase(i)
	else:
		_mirror_filled.append(i)
	_feedback("¡Muy bien! Compara ambos lados del jardín.")
	_render_board()


func _feedback(message: String) -> void:
	if is_instance_valid(_status):
		_status.text = message
		_status.add_theme_color_override("font_color",DARK_GREEN)


func _show_hint() -> void:
	_feedback(HINTS[_level-1])


func _check() -> void:
	var solved := false
	match _level:
		1: solved = _seeds == [1,2,3,4]
		2: solved = _memory_pairs.size() == 6
		3: solved = _pipes == [0,0,0,0,0]
		4: solved = _leaf_pots == [1,2,0]
		5:
			solved = _mirror_filled.size() == _mirror_targets.size()
			for target in _mirror_targets:
				if not _mirror_filled.has(target):
					solved = false
					break
	if solved:
		if not _completed.has(_level):
			_completed.append(_level)
			_completed.sort()
			_save_progress()
		_show_complete()
	else:
		_feedback("Todavía falta un pequeño ajuste. ¡Tú puedes!")


func _show_complete() -> void:
	_screen = "complete"
	var root := _page()
	var back := _soft_button(root,"← NIVELES",Vector2(126,54),_show_levels)
	back.position = Vector2(46,30)
	var panel := _panel(root,Vector2(230,116),Vector2(820,520),PANEL,30)
	var stack := VBoxContainer.new()
	stack.alignment = BoxContainer.ALIGNMENT_CENTER
	stack.add_theme_constant_override("separation",13)
	_margin(panel,52,40,52,40).add_child(stack)
	_label(stack,"✿",60,Color("#8cac77"),HORIZONTAL_ALIGNMENT_CENTER)
	_label(stack,"¡RETO COMPLETADO!",29,INK,HORIZONTAL_ALIGNMENT_CENTER)
	_label(stack,TITLES[_level-1],18,MUTED,HORIZONTAL_ALIGNMENT_CENTER)
	_label(stack,"Un pequeño paso para tu colección de desafíos.",14,MUTED,HORIZONTAL_ALIGNMENT_CENTER)
	_label(stack,"%d DE 5 NIVELES COMPLETADOS" % _completed.size(),11,DARK_GREEN,HORIZONTAL_ALIGNMENT_CENTER)
	var text := "SIGUIENTE DESAFÍO  →" if _level < 5 else "VOLVER AL INICIO"
	var next := _button(stack,text,Vector2(310,60),_continue,DARK_GREEN,14)
	next.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var list := _soft_button(stack,"VER NIVELES",Vector2(240,50),_show_levels)
	list.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_animate(panel)


func _continue() -> void:
	if _level < 5:
		_open_level(_level+1)
	else:
		_show_home()


func _reset() -> void:
	match _level:
		1:
			_seeds = [3,1,4,2]
			_selected_seed = -1
		2:
			_memory_open.clear()
			_memory_pairs.clear()
		3: _pipes = [0,1,3,1,2]
		4:
			_leaf_pots = [-1,-1,-1]
			_selected_leaf = -1
		5: _mirror_filled.clear()
	_show_game()


func _open_level(n: int) -> void:
	if not _unlocked(n):
		return
	_level = clampi(n,1,5)
	_reset()


func _start_next() -> void:
	_open_level(_next_level())


func _next_level() -> int:
	for n in range(1,6):
		if not _completed.has(n):
			return n
	return 5


func _unlocked(n: int) -> bool:
	return n <= 1 or _completed.has(n-1)
