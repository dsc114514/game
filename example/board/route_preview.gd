extends Node2D
## 只画路线，不启动对局、移动玩家或结算格子。

const RouteData = preload("res://example/gameplay/route_data.gd")
const RouteLayout = preload("res://example/board/route_layout.gd")
const FONT = preload("res://example/board/placeholder_font.fnt")
const ORIGIN := Vector2i(128, 192)
const GRID_STEP := Vector2i(128, 112)
const TILE_SIZE := Vector2i(96, 64)
const INK := Color("e3e5e8")
const LINE := Color("858a95")
const FILL := Color("282c34")

@export var standalone: bool = true

var _tiles: Array[Dictionary] = []
var _positions: Dictionary = {}
var _errors := PackedStringArray()
var _edge_count: int = 0


func _ready() -> void:
	_tiles = RouteData.get_tiles()
	_positions = RouteLayout.get_positions()
	_errors = RouteData.validate(_tiles)
	if _errors.is_empty():
		_errors.append_array(RouteLayout.validate(_tiles, _positions))
	if not _errors.is_empty():
		for message in _errors:
			push_error("路线预览: " + message)
		queue_redraw()
		return
	for tile in _tiles:
		_edge_count += tile.next.size()
		var label := Label.new()
		label.name = String(tile.id)
		label.position = Vector2(_center(tile.id) - TILE_SIZE / 2)
		label.size = Vector2(TILE_SIZE)
		label.text = "%s\n%s" % [String(tile.id).to_upper(), String(tile.type).to_upper()]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_override("font", FONT)
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", INK)
		add_child(label)
	print("route_preview: %d tiles, %d directed edges, validation passed" % [_tiles.size(), _edge_count])
	queue_redraw()


func _draw() -> void:
	if standalone:
		draw_string(FONT, Vector2(64, 56), "MVP ROUTE PREVIEW", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, INK)
	if not _errors.is_empty():
		draw_string(FONT, Vector2(64, 104), "ROUTE INVALID - SEE ERROR OUTPUT", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, INK)
		return
	if standalone:
		draw_string(FONT, Vector2(64, 104), "%d TILES / %d EXITS / FORK: A01 OR B01 / STOP: CENTER" % [_tiles.size(), _edge_count], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, INK)
	for tile in _tiles:
		for target in tile.next:
			_draw_edge(_center(tile.id), _center(target))
	for tile in _tiles:
		var rect := Rect2(Vector2(_center(tile.id) - TILE_SIZE / 2), Vector2(TILE_SIZE))
		draw_rect(rect, FILL)
		draw_rect(rect, INK if tile.type in ["spawn", "stop", "branch"] else LINE, false, 1.0)
	if standalone:
		draw_string(FONT, Vector2(64, 624), "ARROWS ARE LEGAL EXITS. POSITIONS ARE DISPLAY ONLY.", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, INK)
		draw_string(FONT, Vector2(64, 656), "SHOP / EVENT: TYPES ONLY. NO TURNS OR TILE EFFECTS YET.", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, INK)


func _center(tile_id: StringName) -> Vector2i:
	return ORIGIN + _positions[String(tile_id)] * GRID_STEP


func _draw_edge(from: Vector2i, to: Vector2i) -> void:
	# 本占位布局均为水平 / 竖直边；方向仅用于画箭头，不推导合法出口。
	var direction := Vector2i(signi(to.x - from.x), signi(to.y - from.y))
	var half_size := TILE_SIZE / 2
	var start := from + direction * half_size
	var end := to - direction * half_size
	var normal := Vector2i(-direction.y, direction.x)
	draw_line(Vector2(start), Vector2(end), LINE, 2.0, false)
	draw_line(Vector2(end), Vector2(end - direction * 8 + normal * 4), INK, 2.0, false)
	draw_line(Vector2(end), Vector2(end - direction * 8 - normal * 4), INK, 2.0, false)
