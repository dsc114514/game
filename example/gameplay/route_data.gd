extends RefCounted
## 固定测试路线。规则只使用 ID / type / next，不依赖显示坐标。

const Rules = preload("res://example/gameplay/mvp_rules.gd")
const TILE_TYPES: PackedStringArray = ["spawn", "stop", "path", "branch", "coin", "shop", "event"]


static func get_tiles() -> Array[Dictionary]:
	# 每次返回独立数据；出生点和停留点 ID 与上一阶段的玩家状态一致。
	return [
		{"id": Rules.SPAWN_TILE_ID, "type": "spawn", "next": ["c01"]},
		{"id": "c01", "type": "coin", "next": ["fork"]},
		{"id": "fork", "type": "branch", "next": ["a01", "b01"]},
		{"id": "a01", "type": "coin", "next": ["shop01"]},
		{"id": "shop01", "type": "shop", "next": ["a02"]},
		{"id": "a02", "type": "path", "next": ["merge"]},
		{"id": "b01", "type": "path", "next": ["event01"]},
		{"id": "event01", "type": "event", "next": ["b02"]},
		{"id": "b02", "type": "coin", "next": ["merge"]},
		{"id": "merge", "type": "path", "next": [Rules.STOP_TILE_ID]},
		{"id": Rules.STOP_TILE_ID, "type": "stop", "next": ["c02"]},
		{"id": "c02", "type": "coin", "next": ["shop02"]},
		{"id": "shop02", "type": "shop", "next": ["event02"]},
		{"id": "event02", "type": "event", "next": ["c03"]},
		{"id": "c03", "type": "coin", "next": ["p01"]},
		{"id": "p01", "type": "path", "next": ["c04"]},
		{"id": "c04", "type": "coin", "next": ["p02"]},
		{"id": "p02", "type": "path", "next": ["c05"]},
		{"id": "c05", "type": "coin", "next": ["p03"]},
		{"id": "p03", "type": "path", "next": ["c06"]},
		{"id": "c06", "type": "coin", "next": ["p04"]},
		{"id": "p04", "type": "path", "next": ["p05"]},
		{"id": "p05", "type": "path", "next": [Rules.SPAWN_TILE_ID]},
	]


static func validate(tiles: Array) -> PackedStringArray:
	var errors := PackedStringArray()
	var by_id: Dictionary = {}
	for index in range(tiles.size()):
		var tile = tiles[index]
		if not tile is Dictionary:
			errors.append("第 %d 项必须是格子 Dictionary" % index)
			continue
		if not _is_id(tile.get("id")):
			errors.append("第 %d 项缺少非空格子 ID" % index)
			continue
		var id := StringName(tile.id)
		if by_id.has(id):
			errors.append("重复格子 ID: %s" % id)
			continue
		by_id[id] = tile
		if not _is_id(tile.get("type")) or not TILE_TYPES.has(String(tile.type)):
			errors.append("格子 %s 的类型无效: %s" % [id, tile.get("type")])
		if not tile.get("next") is Array:
			errors.append("格子 %s 的 next 必须是出口 ID 数组" % id)
			continue
		var exits: Array = tile.next
		if tile.get("type") == "branch":
			if exits.size() < 2:
				errors.append("岔路 %s 至少需要两个出口" % id)
		elif exits.size() != 1:
			errors.append("普通格子 %s 必须恰好有一个出口，实际 %d" % [id, exits.size()])
		var seen: Dictionary = {}
		for target in exits:
			if not _is_id(target):
				errors.append("格子 %s 包含非空 ID 以外的连接目标" % id)
				continue
			var target_id := StringName(target)
			if seen.has(target_id):
				errors.append("格子 %s 的出口重复: %s" % [id, target_id])
			seen[target_id] = true
			if target_id == id:
				errors.append("格子 %s 不能连接自身" % id)
	for id in by_id:
		var tile: Dictionary = by_id[id]
		if not tile.get("next") is Array:
			continue
		for target in tile.next:
			if _is_id(target) and not by_id.has(StringName(target)):
				errors.append("格子 %s 连接到不存在的目标: %s" % [id, target])
	for required in {Rules.SPAWN_TILE_ID: "spawn", Rules.STOP_TILE_ID: "stop"}:
		var expected_type: String = "spawn" if required == Rules.SPAWN_TILE_ID else "stop"
		if not by_id.has(required):
			errors.append("缺少必需格子: %s (%s)" % [required, expected_type])
		elif by_id[required].get("type") != expected_type:
			errors.append("格子 %s 必须使用类型 %s" % [required, expected_type])
	for id in by_id:
		var type = by_id[id].get("type")
		if (type == "spawn" and id != Rules.SPAWN_TILE_ID) or (type == "stop" and id != Rules.STOP_TILE_ID):
			errors.append("出生点 / 停留点类型与配置 ID 不一致: %s" % id)
	# 结构不合法时不进入图遍历，避免校验过程本身因坏数据崩溃。
	if not errors.is_empty():
		return errors
	var reachable := _reachable(by_id, Rules.SPAWN_TILE_ID)
	for id in by_id:
		if not reachable.has(id):
			errors.append("格子 %s 无法从出生点 %s 到达" % [id, Rules.SPAWN_TILE_ID])
	# 反向遍历一次，检查每个出口后方是否仍能走到停留点，包括封闭子环。
	var reverse: Dictionary = {}
	for id in by_id:
		reverse[id] = {"next": []}
	for id in by_id:
		for target in by_id[id].next:
			reverse[StringName(target)].next.append(id)
	var reaches_stop := _reachable(reverse, Rules.STOP_TILE_ID)
	for id in by_id:
		if not reaches_stop.has(id):
			errors.append("格子 %s 无法到达停留点 %s（死路或封闭循环）" % [id, Rules.STOP_TILE_ID])
	var returns_to_stop := false
	for target in by_id[Rules.STOP_TILE_ID].next:
		if StringName(target) != Rules.STOP_TILE_ID and reaches_stop.has(StringName(target)):
			returns_to_stop = true
	if not returns_to_stop:
		errors.append("停留点 %s 离开后无法再次返回" % Rules.STOP_TILE_ID)
	return errors


static func _is_id(value: Variant) -> bool:
	return (value is String or value is StringName) and not String(value).strip_edges().is_empty()


static func _reachable(by_id: Dictionary, start: StringName) -> Dictionary:
	var visited: Dictionary = {start: true}
	var pending: Array[StringName] = [start]
	while not pending.is_empty():
		var current: StringName = pending.pop_back()
		for target in by_id[current].next:
			var id := StringName(target)
			if not visited.has(id):
				visited[id] = true
				pending.append(id)
	return visited
