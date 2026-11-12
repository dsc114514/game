extends RefCounted
## 仅用于占位显示的整数网格坐标。改变布局不会改变任何出口。


static func get_positions() -> Dictionary:
	return {
		"spawn": Vector2i(0, 1), "c01": Vector2i(1, 1), "fork": Vector2i(2, 1),
		"a01": Vector2i(2, 0), "shop01": Vector2i(3, 0), "a02": Vector2i(4, 0),
		"b01": Vector2i(2, 2), "event01": Vector2i(3, 2), "b02": Vector2i(4, 2),
		"merge": Vector2i(4, 1), "center": Vector2i(5, 1), "c02": Vector2i(6, 1),
		"shop02": Vector2i(7, 1), "event02": Vector2i(7, 2), "c03": Vector2i(7, 3),
		"p01": Vector2i(6, 3), "c04": Vector2i(5, 3), "p02": Vector2i(4, 3),
		"c05": Vector2i(3, 3), "p03": Vector2i(2, 3), "c06": Vector2i(1, 3),
		"p04": Vector2i(0, 3), "p05": Vector2i(0, 2),
	}


static func validate(tiles: Array, positions: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	var used: Dictionary = {}
	var ids: Dictionary = {}
	for index in range(tiles.size()):
		var tile: Variant = tiles[index]
		if not tile is Dictionary:
			errors.append("第 %d 项必须是格子 Dictionary" % index)
			continue
		var raw_id: Variant = tile.get("id")
		if not (raw_id is String or raw_id is StringName) or String(raw_id).strip_edges().is_empty():
			errors.append("第 %d 项缺少非空格子 ID" % index)
			continue
		var id := String(raw_id)
		ids[id] = true
		if not positions.has(id):
			errors.append("缺少格子 %s 的显示坐标" % id)
			continue
		var point = positions[id]
		if not point is Vector2i:
			errors.append("格子 %s 的显示坐标必须是 Vector2i" % id)
			continue
		if used.has(point):
			errors.append("格子 %s 与 %s 的显示坐标重叠" % [id, used[point]])
		used[point] = id
	for id in positions:
		if not ids.has(id):
			errors.append("显示坐标引用不存在的格子: %s" % id)
	return errors
