extends SceneTree
## 正常路线和刻意损坏的数据均在真实 Godot 中验证；失败退出码为 1。

const RouteData = preload("res://example/gameplay/route_data.gd")
const RouteLayout = preload("res://example/board/route_layout.gd")
const Rules = preload("res://example/gameplay/mvp_rules.gd")

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_test_route()
	_test_invalid_data()
	_test_layout()
	print("route_data: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)


func _tile(tiles: Array, id: StringName) -> Dictionary:
	for tile in tiles:
		if tile.id == id:
			return tile
	return {}


func _expect_error(tiles: Array, fragment: String) -> void:
	var errors := RouteData.validate(tiles)
	_check(not errors.is_empty(), "坏数据应被拒绝: " + fragment)
	_check("\n".join(errors).contains(fragment), "应有明确错误 '%s'，实际: %s" % [fragment, errors])


func _test_route() -> void:
	var tiles := RouteData.get_tiles()
	_check(tiles.size() >= 16 and tiles.size() <= 24, "测试路线为 16～24 格")
	_check(RouteData.validate(tiles).is_empty(), "固定路线通过全部图校验")
	var ids: Dictionary = {}
	var types: Dictionary = {}
	var edge_count := 0
	var merge_inputs := 0
	for tile in tiles:
		_check(not ids.has(StringName(tile.id)), "唯一 ID: %s" % tile.id)
		ids[StringName(tile.id)] = true
		types[tile.type] = true
		_check(not tile.has("position"), "规则数据不包含显示位置")
		_check(tile.next.size() == (2 if tile.type == "branch" else 1), "普通节点单出口 / 岔路多出口")
		for target in tile.next:
			_check(not _tile(tiles, target).is_empty(), "连接目标存在: %s" % target)
			edge_count += 1
			if target == "merge":
				merge_inputs += 1
	_check(edge_count == 24 and merge_inputs == 2, "24 条有向连接和双入口汇合点")
	for type in ["spawn", "stop", "coin", "shop", "event", "branch"]:
		_check(types.has(type), "包含必需类型: " + type)
	_check(Rules.SPAWN_TILE_ID != Rules.STOP_TILE_ID, "出生点与停留点分开")
	# 从出生点实际按合法出口走三圈，分别选择上下分支，覆盖全部格子。
	var visited: Dictionary = {}
	for choice in ["a01", "b01"]:
		var current := Rules.SPAWN_TILE_ID
		var stop_count := 0
		var returned := false
		for step in range(64):
			visited[current] = true
			var tile := _tile(tiles, current)
			var target: StringName = StringName(choice) if tile.type == "branch" else StringName(tile.next[0])
			_check(tile.next.has(target), "逐格行走只采用合法出口")
			current = target
			if current == Rules.STOP_TILE_ID:
				stop_count += 1
			if current == Rules.SPAWN_TILE_ID:
				returned = true
			if stop_count == 3:
				break
		_check(stop_count == 3 and returned, "分支 %s 能循环三次落在停留点" % choice)
	_check(visited.size() == tiles.size(), "两条分支行走覆盖所有测试格子")
	tiles[0].next.clear()
	_check(RouteData.get_tiles()[0].next == ["c01"], "读取的数据相互隔离")


func _test_invalid_data() -> void:
	var tiles := RouteData.get_tiles()
	tiles.append(tiles[0].duplicate(true))
	_expect_error(tiles, "重复格子 ID: spawn")
	tiles = RouteData.get_tiles()
	_tile(tiles, &"c01").next = ["missing"]
	_expect_error(tiles, "c01 连接到不存在的目标: missing")
	for id in [Rules.SPAWN_TILE_ID, Rules.STOP_TILE_ID]:
		tiles = RouteData.get_tiles()
		tiles.erase(_tile(tiles, id))
		_expect_error(tiles, "缺少必需格子: %s" % id)
	tiles = RouteData.get_tiles()
	tiles.append({"id": "island1", "type": "path", "next": ["island2"]})
	tiles.append({"id": "island2", "type": "path", "next": ["island1"]})
	_expect_error(tiles, "island1 无法从出生点")
	_expect_error(tiles, "island2 无法到达停留点")
	# 可从出生点进入的封闭分支，不能只靠“每格有出口”误判为有效。
	tiles = RouteData.get_tiles()
	_tile(tiles, &"event01").next = ["b01"]
	_expect_error(tiles, "b01 无法到达停留点")
	tiles = RouteData.get_tiles()
	_tile(tiles, Rules.STOP_TILE_ID).next = ["center"]
	_expect_error(tiles, "center 不能连接自身")
	tiles = RouteData.get_tiles()
	_tile(tiles, Rules.STOP_TILE_ID).next = []
	_expect_error(tiles, "center 必须恰好有一个出口")
	tiles = RouteData.get_tiles()
	_tile(tiles, &"fork").next = ["a01"]
	_expect_error(tiles, "岔路 fork 至少需要两个出口")
	tiles = RouteData.get_tiles()
	_tile(tiles, &"fork").next = ["a01", "a01"]
	_expect_error(tiles, "fork 的出口重复: a01")
	tiles = RouteData.get_tiles()
	_tile(tiles, &"c01").next = ["fork", "a01"]
	_expect_error(tiles, "c01 必须恰好有一个出口")
	tiles = RouteData.get_tiles()
	_tile(tiles, &"c01").type = "invalid"
	_expect_error(tiles, "c01 的类型无效")
	tiles = RouteData.get_tiles()
	_tile(tiles, Rules.STOP_TILE_ID).type = "coin"
	_expect_error(tiles, "center 必须使用类型 stop")
	_expect_error([], "缺少必需格子")
	_expect_error([null], "必须是格子 Dictionary")
	_expect_error([{}], "缺少非空格子 ID")
	_expect_error([{"id": 42}], "缺少非空格子 ID")
	_expect_error([{"id": "   "}], "缺少非空格子 ID")
	_expect_error([{"id": "bad", "type": null, "next": []}], "bad 的类型无效")
	_expect_error([{"id": "bad", "type": "path", "next": null}], "bad 的 next 必须是出口 ID 数组")
	_expect_error([{"id": "bad", "type": "path", "next": [null]}], "bad 包含非空 ID 以外的连接目标")
	for bad_type in [42, [], {}, Vector2i.ZERO]:
		_expect_error([{"id": "bad", "type": bad_type, "next": []}], "bad 的类型无效")
		for id in [Rules.SPAWN_TILE_ID, Rules.STOP_TILE_ID]:
			tiles = RouteData.get_tiles()
			_tile(tiles, id).type = bad_type
			_expect_error(tiles, "%s 的类型无效" % id)


func _test_layout() -> void:
	var tiles := RouteData.get_tiles()
	var positions := RouteLayout.get_positions()
	_check(RouteLayout.validate(tiles, positions).is_empty(), "每格都有唯一整数坐标")
	positions["spawn"] = Vector2i(99, 99)
	_check(RouteData.validate(tiles).is_empty(), "移动显示坐标不改变连接规则")
	_check(RouteLayout.get_positions()["spawn"] == Vector2i(0, 1), "显示布局读取隔离")
	positions.erase("spawn")
	_check("\n".join(RouteLayout.validate(tiles, positions)).contains("缺少格子 spawn"), "缺少坐标给出明确错误")
	positions = RouteLayout.get_positions()
	positions["spawn"] = positions["c01"]
	_check("\n".join(RouteLayout.validate(tiles, positions)).contains("显示坐标重叠"), "重叠坐标给出明确错误")
	positions = RouteLayout.get_positions()
	positions["spawn"] = Vector2(0.5, 1)
	_check("\n".join(RouteLayout.validate(tiles, positions)).contains("必须是 Vector2i"), "拒绝非整数坐标")
	# 显示校验也是公共诊断入口，不能假定调用者已经跑过规则校验。
	for bad_tile in [null, 42, "spawn", []]:
		_expect_layout_error([bad_tile], {}, "必须是格子 Dictionary")
	for bad_tile in [{}, {"id": null}, {"id": 42}, {"id": []}, {"id": "   "}]:
		_expect_layout_error([bad_tile], {}, "缺少非空格子 ID")
	positions = RouteLayout.get_positions()
	positions["missing"] = Vector2i(99, 99)
	_expect_layout_error(tiles, positions, "显示坐标引用不存在的格子: missing")


func _expect_layout_error(tiles: Array, positions: Dictionary, fragment: String) -> void:
	var errors := RouteLayout.validate(tiles, positions)
	_check(not errors.is_empty(), "坏显示数据应被拒绝: " + fragment)
	_check("\n".join(errors).contains(fragment), "应有明确显示错误 '%s'，实际: %s" % [fragment, errors])
