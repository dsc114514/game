extends SceneTree
## 验证场景实例化和可视节点。图形模式另存实际渲染截图供人工检查。

const Preview = preload("res://example/board/route_preview.tscn")
const RouteData = preload("res://example/gameplay/route_data.gd")

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var preview := Preview.instantiate()
	root.add_child(preview)
	await process_frame
	var tiles := RouteData.get_tiles()
	_check(preview.get_child_count() == tiles.size(), "预览为每个格子生成一个标签")
	for tile in tiles:
		var label := preview.get_node_or_null(NodePath(String(tile.id))) as Label
		_check(label != null, "生成标签: %s" % tile.id)
		if label == null:
			continue
		_check(label.text == "%s\n%s" % [String(tile.id).to_upper(), String(tile.type).to_upper()], "标签显示 ID 和类型")
		_check(Rect2(Vector2.ZERO, Vector2(1152, 720)).encloses(label.get_rect()), "格子完整处于视口内")
		_check(label.get_minimum_size().x <= label.size.x, "格子文字没有横向溢出")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		_check(not image.is_empty(), "取得实际渲染画面")
		var path := "res://.godot/route_preview.png"
		_check(image.save_png(path) == OK, "保存实际渲染截图")
		print("route_preview screenshot: ", ProjectSettings.globalize_path(path))
	print("route_preview_test: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)
