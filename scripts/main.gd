extends Node2D

const WORLD_RECT := Rect2(Vector2(-2100.0, -1300.0), Vector2(4200.0, 2600.0))
const MIN_ZOOM := 0.38
const MAX_ZOOM := 2.4
const INITIAL_ZOOM := 0.78

const TREE_COLORS := [
	Color("#6b9f68"),
	Color("#82b76f"),
	Color("#4e8d68"),
	Color("#a5c875"),
	Color("#78ad83")
]

var _camera: Camera2D
var _mouse_drag_active := false
var _touch_positions: Dictionary = {}
var _previous_pinch_distance := 0.0


func _ready() -> void:
	_camera = Camera2D.new()
	_camera.name = "WorldCamera"
	_camera.position = Vector2.ZERO
	_camera.zoom = Vector2.ONE * INITIAL_ZOOM
	add_child(_camera)
	_camera.make_current()
	_clamp_camera()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_mouse_drag_active = event.pressed
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_set_zoom(_camera.zoom.x * 1.12)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_set_zoom(_camera.zoom.x / 1.12)

	elif event is InputEventMouseMotion and _mouse_drag_active:
		_camera.position -= event.relative / _camera.zoom.x
		_clamp_camera()

	elif event is InputEventScreenTouch:
		if event.pressed:
			_touch_positions[event.index] = event.position
			if _touch_positions.size() >= 2:
				_previous_pinch_distance = _get_pinch_distance()
		else:
			_touch_positions.erase(event.index)
			_previous_pinch_distance = 0.0

	elif event is InputEventScreenDrag:
		if _touch_positions.has(event.index):
			_touch_positions[event.index] = event.position

		if _touch_positions.size() == 1:
			_camera.position -= event.relative / _camera.zoom.x
			_clamp_camera()
		elif _touch_positions.size() >= 2:
			var current_distance := _get_pinch_distance()
			if _previous_pinch_distance > 0.0 and current_distance > 0.0:
				_set_zoom(_camera.zoom.x * (current_distance / _previous_pinch_distance))
			_previous_pinch_distance = current_distance


func _set_zoom(value: float) -> void:
	var zoom_value := clampf(value, MIN_ZOOM, MAX_ZOOM)
	_camera.zoom = Vector2.ONE * zoom_value
	_clamp_camera()


func _get_pinch_distance() -> float:
	var points: Array = _touch_positions.values()
	if points.size() < 2:
		return 0.0
	return points[0].distance_to(points[1])


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

	# Distant hills create depth without changing the flat 2D camera.
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

	for i in flower_positions.size():
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
