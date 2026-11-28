extends Node2D

const WORLD_RECT := Rect2(Vector2(-2100.0, -1300.0), Vector2(4200.0, 2600.0))
const MIN_ZOOM := 0.38
const MAX_ZOOM := 2.4
const INITIAL_ZOOM := 0.78
const MAX_WORLD_OBJECTS := 2500

const TREE_COLORS := [
	Color("#6b9f68"),
	Color("#82b76f"),
	Color("#4e8d68"),
	Color("#a5c875"),
	Color("#78ad83")
]

var _camera: Camera2D
var _ui_layer: CanvasLayer
var _tool_buttons: Dictionary = {}
var _brush_size_label: Label
var _tool_button_group: ButtonGroup

var _active_tool := "terrain"
var _brush_size := 112.0
var _mouse_paint_active := false
var _mouse_pan_active := false
var _touch_positions: Dictionary = {}
var _previous_pinch_distance := 0.0
var _last_brush_position := Vector2(INF, INF)

var _terrain_patches: Array[Dictionary] = []
var _water_patches: Array[Dictionary] = []
var _plants: Array[Dictionary] = []


func _ready() -> void:
	_camera = Camera2D.new()
	_camera.name = "WorldCamera"
	_camera.position = Vector2.ZERO
	_camera.zoom = Vector2.ONE * INITIAL_ZOOM
	add_child(_camera)
	_camera.make_current()
	_clamp_camera()
	_build_interface()
	queue_redraw()


func _build_interface() -> void:
	_ui_layer = CanvasLayer.new()
	_ui_layer.name = "EditorInterface"
	add_child(_ui_layer)

	var root := Control.new()
	root.name = "InterfaceRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	_ui_layer.add_child(root)

	_build_header(root)
	_build_toolbar(root)


func _build_header(root: Control) -> void:
	var header := _make_panel(root, Vector2(276.0, 78.0))
	header.position = Vector2(22.0, 20.0)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 9)
	margin.add_theme_constant_override("margin_bottom", 8)
	header.add_child(margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 1)
	margin.add_child(stack)

	var title := Label.new()
	title.text = "ViVARiA"
	title.add_theme_color_override("font_color", Color("#344d3b"))
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_font_override("font", ThemeDB.fallback_font)
	stack.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "CREA · EXPLORA · EXPERIMENTA"
	subtitle.add_theme_color_override("font_color", Color("#71836b"))
	subtitle.add_theme_font_size_override("font_size", 10)
	stack.add_child(subtitle)

	var status := _make_panel(root, Vector2(190.0, 62.0))
	status.anchor_left = 1.0
	status.anchor_right = 1.0
	status.offset_left = -212.0
	status.offset_right = -22.0
	status.offset_top = 20.0
	status.offset_bottom = 82.0

	var status_margin := MarginContainer.new()
	status_margin.add_theme_constant_override("margin_left", 15)
	status_margin.add_theme_constant_override("margin_right", 15)
	status_margin.add_theme_constant_override("margin_top", 7)
	status_margin.add_theme_constant_override("margin_bottom", 7)
	status.add_child(status_margin)

	var status_stack := VBoxContainer.new()
	status_stack.add_theme_constant_override("separation", 1)
	status_margin.add_child(status_stack)

	var world_label := Label.new()
	world_label.text = "MUNDO 01"
	world_label.add_theme_color_override("font_color", Color("#425b43"))
	world_label.add_theme_font_size_override("font_size", 14)
	world_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_stack.add_child(world_label)

	var world_hint := Label.new()
	world_hint.text = "DOS DEDOS · MOVER Y ZOOM"
	world_hint.add_theme_color_override("font_color", Color("#788b72"))
	world_hint.add_theme_font_size_override("font_size", 9)
	world_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_stack.add_child(world_hint)


func _build_toolbar(root: Control) -> void:
	var toolbar := _make_panel(root, Vector2(822.0, 104.0))
	toolbar.anchor_left = 0.5
	toolbar.anchor_right = 0.5
	toolbar.anchor_top = 1.0
	toolbar.anchor_bottom = 1.0
	toolbar.offset_left = -411.0
	toolbar.offset_right = 411.0
	toolbar.offset_top = -124.0
	toolbar.offset_bottom = -20.0

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	toolbar.add_child(margin)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 9)
	margin.add_child(row)

	_tool_button_group = ButtonGroup.new()
	var tool_definitions := [
		{"id": "terrain", "label": "TIERRA"},
		{"id": "water", "label": "AGUA"},
		{"id": "plants", "label": "PLANTAS"},
		{"id": "eraser", "label": "BORRAR"}
	]

	for definition in tool_definitions:
		var tool_id: String = definition["id"]
		var button := Button.new()
		button.text = definition["label"]
		button.custom_minimum_size = Vector2(126.0, 62.0)
		button.toggle_mode = true
		button.button_group = _tool_button_group
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 13)
		button.pressed.connect(_on_tool_selected.bind(tool_id))
		row.add_child(button)
		_tool_buttons[tool_id] = button
		_style_tool_button(button, tool_id == _active_tool)

	var separator := VSeparator.new()
	separator.custom_minimum_size = Vector2(1.0, 42.0)
	row.add_child(separator)

	var brush_caption := Label.new()
	brush_caption.text = "TAMAÑO"
	brush_caption.add_theme_color_override("font_color", Color("#71836b"))
	brush_caption.add_theme_font_size_override("font_size", 10)
	brush_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(brush_caption)

	var smaller_button := _make_small_button("−")
	smaller_button.pressed.connect(_change_brush_size.bind(-1))
	row.add_child(smaller_button)

	_brush_size_label = Label.new()
	_brush_size_label.custom_minimum_size = Vector2(38.0, 0.0)
	_brush_size_label.text = str(roundi(_brush_size))
	_brush_size_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_brush_size_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_brush_size_label.add_theme_color_override("font_color", Color("#425b43"))
	_brush_size_label.add_theme_font_size_override("font_size", 14)
	row.add_child(_brush_size_label)

	var larger_button := _make_small_button("+")
	larger_button.pressed.connect(_change_brush_size.bind(1))
	row.add_child(larger_button)

	_tool_buttons[_active_tool].button_pressed = true


func _make_panel(parent: Control, minimum_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum_size
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#f7f5e9")
	style.border_color = Color("#ffffff")
	style.set_border_width_all(2)
	style.set_corner_radius_all(22)
	style.shadow_color = Color(0.12, 0.20, 0.12, 0.16)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0.0, 4.0)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel


func _make_small_button(text_value: String) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(42.0, 46.0)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 20)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#e9edda")
	normal.set_corner_radius_all(14)
	button.add_theme_stylebox_override("normal", normal)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color("#dce8cd")
	hover.set_corner_radius_all(14)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_color_override("font_color", Color("#405b43"))
	return button


func _style_tool_button(button: Button, selected: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#e8edda") if selected else Color("#f0f0e4")
	normal.border_color = Color("#b5c99c") if selected else Color("#e4e7d8")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(16)
	button.add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color("#dfe9d0")
	hover.set_corner_radius_all(16)
	button.add_theme_stylebox_override("hover", hover)

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color("#d5e5c7")
	pressed.set_border_width_all(1)
	pressed.set_border_color(Color("#9dbb88"))
	pressed.set_corner_radius_all(16)
	button.add_theme_stylebox_override("pressed", pressed)

	button.add_theme_color_override("font_color", Color("#405b43") if selected else Color("#687b61"))
	button.add_theme_color_override("font_hover_color", Color("#354e39"))
	button.add_theme_color_override("font_pressed_color", Color("#354e39"))


func _on_tool_selected(tool_id: String) -> void:
	_active_tool = tool_id
	for key in _tool_buttons:
		var button: Button = _tool_buttons[key]
		_style_tool_button(button, key == _active_tool)
		button.button_pressed = key == _active_tool


func _change_brush_size(direction: int) -> void:
	_brush_size = clampf(_brush_size + float(direction) * 28.0, 52.0, 220.0)
	if is_instance_valid(_brush_size_label):
		_brush_size_label.text = str(roundi(_brush_size))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_mouse_paint_active = event.pressed
			if event.pressed:
				_last_brush_position = Vector2(INF, INF)
				_apply_brush(_screen_to_world(event.position), true)
		elif event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
			_mouse_pan_active = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_set_zoom(_camera.zoom.x * 1.12)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_set_zoom(_camera.zoom.x / 1.12)

	elif event is InputEventMouseMotion:
		if _mouse_pan_active:
			_camera.position -= event.relative / _camera.zoom.x
			_clamp_camera()
		elif _mouse_paint_active:
			_apply_brush(_screen_to_world(event.position))

	elif event is InputEventScreenTouch:
		if event.pressed:
			_touch_positions[event.index] = event.position
			if _touch_positions.size() == 1:
				_last_brush_position = Vector2(INF, INF)
				_apply_brush(_screen_to_world(event.position), true)
			elif _touch_positions.size() >= 2:
				_previous_pinch_distance = _get_pinch_distance()
		else:
			_touch_positions.erase(event.index)
			if _touch_positions.size() < 2:
				_previous_pinch_distance = 0.0
			if _touch_positions.size() == 1:
				_last_brush_position = Vector2(INF, INF)

	elif event is InputEventScreenDrag:
		var previous_center := _get_touch_center()
		_touch_positions[event.index] = event.position
		if _touch_positions.size() == 1:
			_apply_brush(_screen_to_world(event.position))
		elif _touch_positions.size() >= 2:
			var current_center := _get_touch_center()
			var current_distance := _get_pinch_distance()
			_camera.position -= (current_center - previous_center) / _camera.zoom.x
			if _previous_pinch_distance > 0.0 and current_distance > 0.0:
				_set_zoom(_camera.zoom.x * (current_distance / _previous_pinch_distance))
			_previous_pinch_distance = current_distance
			_clamp_camera()


func _screen_to_world(screen_position: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen_position


func _apply_brush(world_position: Vector2, force: bool = false) -> void:
	if not WORLD_RECT.has_point(world_position):
		return

	var spacing := maxf(18.0, _brush_size * 0.30)
	if not force and _last_brush_position.distance_to(world_position) < spacing:
		return

	match _active_tool:
		"terrain":
			if _terrain_patches.size() < MAX_WORLD_OBJECTS:
				_terrain_patches.append({
					"position": world_position,
					"radius": _brush_size * randf_range(0.88, 1.12),
					"seed": randi()
				})
		"water":
			if _water_patches.size() < MAX_WORLD_OBJECTS:
				_water_patches.append({
					"position": world_position,
					"radius": _brush_size * randf_range(0.82, 1.10),
					"seed": randi()
				})
		"plants":
			if force or _last_brush_position.distance_to(world_position) >= _brush_size * 0.75:
				if _plants.size() < MAX_WORLD_OBJECTS:
					_plants.append({
						"position": world_position,
						"kind": randi_range(0, 2),
						"scale": randf_range(0.82, 1.20),
						"seed": randi()
					})
		"eraser":
			_erase_at(world_position)

	_last_brush_position = world_position
	queue_redraw()


func _erase_at(world_position: Vector2) -> void:
	for i in range(_terrain_patches.size() - 1, -1, -1):
		var patch: Dictionary = _terrain_patches[i]
		var radius: float = float(patch["radius"])
		var patch_position: Vector2 = patch["position"]
		if patch_position.distance_to(world_position) <= _brush_size + radius * 0.65:
			_terrain_patches.remove_at(i)

	for i in range(_water_patches.size() - 1, -1, -1):
		var patch: Dictionary = _water_patches[i]
		var radius: float = float(patch["radius"])
		var patch_position: Vector2 = patch["position"]
		if patch_position.distance_to(world_position) <= _brush_size + radius * 0.65:
			_water_patches.remove_at(i)

	for i in range(_plants.size() - 1, -1, -1):
		var plant: Dictionary = _plants[i]
		var plant_position: Vector2 = plant["position"]
		if plant_position.distance_to(world_position) <= _brush_size + 42.0:
			_plants.remove_at(i)


func _get_touch_center() -> Vector2:
	var points: Array = _touch_positions.values()
	if points.is_empty():
		return Vector2.ZERO
	var total := Vector2.ZERO
	for point in points:
		total += point
	return total / float(points.size())


func _get_pinch_distance() -> float:
	var points: Array = _touch_positions.values()
	if points.size() < 2:
		return 0.0
	return points[0].distance_to(points[1])


func _set_zoom(value: float) -> void:
	var zoom_value := clampf(value, MIN_ZOOM, MAX_ZOOM)
	_camera.zoom = Vector2.ONE * zoom_value
	_clamp_camera()


func _clamp_camera() -> void:
	var half_view := get_viewport_rect().size / (2.0 * _camera.zoom.x)
	var min_x := WORLD_RECT.position.x + minf(half_view.x, WORLD_RECT.size.x * 0.5)
	var max_x := WORLD_RECT.end.x - minf(half_view.x, WORLD_RECT.size.x * 0.5)
	var min_y := WORLD_RECT.position.y + minf(half_view.y, WORLD_RECT.size.y * 0.5)
	var max_y := WORLD_RECT.end.y - minf(half_view.y, WORLD_RECT.size.y * 0.5)
	_camera.position.x = clampf(_camera.position.x, min_x, max_x)
	_camera.position.y = clampf(_camera.position.y, min_y, max_y)


func _draw() -> void:
	draw_rect(WORLD_RECT, Color("#dcebc2"), true)

	draw_colored_polygon(PackedVector2Array([
		Vector2(-2100, -470), Vector2(-1780, -980), Vector2(-1260, -1080),
		Vector2(-760, -820), Vector2(-220, -1050), Vector2(360, -760),
		Vector2(900, -990), Vector2(1500, -760), Vector2(2100, -940),
		Vector2(2100, 1300), Vector2(-2100, 1300)
	]), Color("#c4dca0"))

	draw_colored_polygon(PackedVector2Array([
		Vector2(-2100, 40), Vector2(-1660, -360), Vector2(-1160, -300),
		Vector2(-660, -80), Vector2(-110, -340), Vector2(420, -80),
		Vector2(980, -330), Vector2(1500, -90), Vector2(2100, -260),
		Vector2(2100, 1300), Vector2(-2100, 1300)
	]), Color("#a9cf8b"))

	_draw_pond()
	_draw_meadow_paths()
	_draw_tree_groups()
	_draw_flowers()
	_draw_foreground_bushes()
	_draw_terrain_patches()
	_draw_water_patches()
	_draw_placed_plants()


func _draw_pond() -> void:
	var pond_center := Vector2(410, 410)
	draw_circle(pond_center, 360.0, Color("#79c6bd"))
	draw_circle(pond_center + Vector2(-12, -18), 325.0, Color("#8ed6c9"))
	draw_arc(pond_center + Vector2(-12, -18), 275.0, 0.15, 2.65, 42, Color("#b8e8d6"), 8.0, true)
	draw_arc(pond_center + Vector2(30, 22), 205.0, 3.25, 5.65, 36, Color("#65b8b0"), 6.0, true)
	draw_circle(pond_center + Vector2(-130, -115), 18.0, Color("#c8eee0"))
	draw_circle(pond_center + Vector2(145, 96), 11.0, Color("#c8eee0"))


func _draw_meadow_paths() -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(-2100, 420), Vector2(-1500, 350), Vector2(-900, 470),
		Vector2(-500, 380), Vector2(-120, 520), Vector2(310, 470),
		Vector2(680, 620), Vector2(1130, 550), Vector2(1600, 700),
		Vector2(2100, 630), Vector2(2100, 1300), Vector2(-2100, 1300)
	]), Color("#c1d99a"))


func _draw_tree_groups() -> void:
	for x in range(-1900, 1901, 245):
		for y in [-820, -590, 850, 1080]:
			if x > -250 and x < 1050 and y > 0:
				continue
			var index := int(abs(float(x + y) / 17.0)) % TREE_COLORS.size()
			var size_factor := 0.82 + float((abs(x * 3 + y) % 5)) * 0.07
			_draw_tree(Vector2(x, y), size_factor, TREE_COLORS[index])

	_draw_tree(Vector2(-1140, 190), 1.35, Color("#5f9867"))
	_draw_tree(Vector2(1330, 210), 1.28, Color("#83b86d"))
	_draw_tree(Vector2(-250, -720), 1.25, Color("#76aa70"))
	_draw_tree(Vector2(1030, -720), 1.18, Color("#a1c879"))


func _draw_tree(position: Vector2, scale_factor: float, canopy_color: Color) -> void:
	var trunk_color := Color("#98634c")
	var s := scale_factor

	draw_rect(
		Rect2(position + Vector2(-12.0 * s, -4.0 * s), Vector2(24.0 * s, 76.0 * s)),
		trunk_color
	)
	draw_line(
		position + Vector2(0.0, 26.0 * s),
		position + Vector2(-30.0 * s, 2.0 * s),
		trunk_color,
		8.0 * s,
		true
	)
	draw_line(
		position + Vector2(0.0, 14.0 * s),
		position + Vector2(28.0 * s, -15.0 * s),
		trunk_color,
		7.0 * s,
		true
	)

	draw_circle(position + Vector2(0.0, -52.0 * s), 57.0 * s, canopy_color)
	draw_circle(position + Vector2(-42.0 * s, -26.0 * s), 39.0 * s, canopy_color.lightened(0.04))
	draw_circle(position + Vector2(40.0 * s, -25.0 * s), 40.0 * s, canopy_color.darkened(0.04))
	draw_circle(position + Vector2(-12.0 * s, -88.0 * s), 34.0 * s, canopy_color.lightened(0.08))
	draw_circle(position + Vector2(20.0 * s, -48.0 * s), 25.0 * s, canopy_color.darkened(0.07))
	draw_circle(position + Vector2(-28.0 * s, -63.0 * s), 6.0 * s, Color("#c4d989"))
	draw_circle(position + Vector2(30.0 * s, -35.0 * s), 5.0 * s, Color("#d2df91"))


func _draw_flowers() -> void:
	var flower_positions := [
		Vector2(-1420, 430), Vector2(-1280, 520), Vector2(-1030, 690),
		Vector2(-760, 520), Vector2(-420, 660), Vector2(-170, 850),
		Vector2(820, 760), Vector2(1120, 830), Vector2(1510, 570),
		Vector2(1730, 860), Vector2(-1660, 980)
	]

	for i in range(flower_positions.size()):
		var p: Vector2 = flower_positions[i]
		var petal_color := Color("#f2a1a0") if i % 3 == 0 else Color("#f3d477")
		draw_line(p, p + Vector2(0, -22), Color("#659a62"), 4.0, true)
		draw_circle(p + Vector2(0, -25), 8.0, petal_color)
		draw_circle(p + Vector2(-7, -25), 6.0, petal_color.lightened(0.08))
		draw_circle(p + Vector2(7, -25), 6.0, petal_color.lightened(0.08))
		draw_circle(p + Vector2(0, -25), 3.0, Color("#f8e5a2"))


func _draw_foreground_bushes() -> void:
	for x in range(-2050, 2051, 190):
		if x > -80 and x < 900:
			continue
		var y := 1160.0 + float(abs(x) % 4) * 20.0
		draw_circle(Vector2(x, y), 92.0, Color("#7eaa70"))
		draw_circle(Vector2(x + 48, y - 28), 65.0, Color("#92bc77"))
		draw_circle(Vector2(x - 48, y - 18), 58.0, Color("#6d9b69"))


func _create_organic_shape(center: Vector2, radius: float, seed_value: int, points_count: int = 22) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var points := PackedVector2Array()
	for i in range(points_count):
		var angle := TAU * float(i) / float(points_count)
		var distance := radius * rng.randf_range(0.84, 1.14)
		points.append(center + Vector2(cos(angle), sin(angle)) * distance)
	return points


func _draw_terrain_patches() -> void:
	for patch in _terrain_patches:
		var center: Vector2 = patch["position"]
		var radius: float = float(patch["radius"])
		var seed_value: int = int(patch["seed"])
		draw_colored_polygon(_create_organic_shape(center, radius, seed_value), Color("#b99468"))
		draw_colored_polygon(_create_organic_shape(center + Vector2(-5.0, -7.0), radius * 0.72, seed_value + 31), Color("#d1b184"))
		draw_arc(center, radius * 0.78, 0.25, 2.55, 28, Color("#e2c79e"), 4.0, true)


func _draw_water_patches() -> void:
	for patch in _water_patches:
		var center: Vector2 = patch["position"]
		var radius: float = float(patch["radius"])
		var seed_value: int = int(patch["seed"])
		draw_colored_polygon(_create_organic_shape(center, radius, seed_value), Color("#55aeb0"))
		draw_colored_polygon(_create_organic_shape(center + Vector2(-7.0, -9.0), radius * 0.77, seed_value + 47), Color("#83d2c9"))
		draw_arc(center + Vector2(-8.0, -10.0), radius * 0.55, 3.5, 5.4, 24, Color("#c0eee0"), 5.0, true)
		draw_line(center + Vector2(-radius * 0.30, -radius * 0.10), center + Vector2(radius * 0.18, -radius * 0.18), Color("#d8f4df"), 4.0, true)


func _draw_placed_plants() -> void:
	for plant in _plants:
		var position: Vector2 = plant["position"]
		var scale_factor: float = float(plant["scale"])
		match int(plant["kind"]):
			0:
				_draw_placed_flower(position, scale_factor)
			1:
				_draw_placed_bush(position, scale_factor)
			2:
				_draw_placed_sapling(position, scale_factor)


func _draw_placed_flower(position: Vector2, scale_factor: float) -> void:
	var stem_color := Color("#57895c")
	var flower_color := Color("#f2a0a0")
	var s := scale_factor
	draw_line(position, position + Vector2(0.0, -34.0 * s), stem_color, 4.0 * s, true)
	draw_line(position + Vector2(0.0, -17.0 * s), position + Vector2(-10.0 * s, -24.0 * s), stem_color, 3.0 * s, true)
	draw_circle(position + Vector2(0.0, -38.0 * s), 8.0 * s, flower_color)
	draw_circle(position + Vector2(-8.0 * s, -38.0 * s), 6.0 * s, flower_color.lightened(0.08))
	draw_circle(position + Vector2(8.0 * s, -38.0 * s), 6.0 * s, flower_color.lightened(0.08))
	draw_circle(position + Vector2(0.0, -38.0 * s), 3.5 * s, Color("#f5d77f"))


func _draw_placed_bush(position: Vector2, scale_factor: float) -> void:
	var s := scale_factor
	draw_circle(position, 29.0 * s, Color("#5f9663"))
	draw_circle(position + Vector2(-20.0 * s, -10.0 * s), 22.0 * s, Color("#7faf70"))
	draw_circle(position + Vector2(19.0 * s, -13.0 * s), 24.0 * s, Color("#8dbb75"))
	draw_circle(position + Vector2(-3.0 * s, -28.0 * s), 19.0 * s, Color("#9ac57d"))


func _draw_placed_sapling(position: Vector2, scale_factor: float) -> void:
	var s := scale_factor
	draw_line(position + Vector2(0.0, 12.0 * s), position + Vector2(0.0, -35.0 * s), Color("#98634c"), 6.0 * s, true)
	draw_circle(position + Vector2(0.0, -43.0 * s), 25.0 * s, Color("#77a96b"))
	draw_circle(position + Vector2(-18.0 * s, -32.0 * s), 15.0 * s, Color("#91bd78"))
	draw_circle(position + Vector2(17.0 * s, -31.0 * s), 15.0 * s, Color("#a2c77d"))
