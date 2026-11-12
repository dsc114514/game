extends SceneTree
## 经 Viewport 注入鼠标事件点击真实按钮，完成从开局到胜利及重开的界面闭环。
## 图形模式会额外保存真实截图；不向玩家状态注入资金、星数或位置。

const GameScene = preload("res://example/board/game.tscn")
const Turn = preload("res://example/gameplay/turn_controller.gd")
const Rules = preload("res://example/gameplay/mvp_rules.gd")
const Route = preload("res://example/gameplay/route_data.gd")

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)


func _click(scene, path: String) -> void:
	await process_frame
	var button := scene.get_node("UI/" + path) as Button
	_check(button != null and not button.disabled, "可点击按钮: " + path)
	if button != null and not button.disabled:
		var point := button.get_global_rect().get_center()
		var motion := InputEventMouseMotion.new()
		motion.position = point
		root.push_input(motion, true)
		for pressed in [true, false]:
			var event := InputEventMouseButton.new()
			event.button_index = MOUSE_BUTTON_LEFT
			event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
			event.position = point
			event.global_position = point
			event.pressed = pressed
			root.push_input(event, true)
	await process_frame


func _drain_ui(scene) -> void:
	for step in range(16):
		var state: Dictionary = scene._game.get_snapshot()
		if state.turn_phase == Turn.Phase.MOVING:
			_check(scene.get_node("UI/Roll").disabled, "移动时掷骰按钮禁用")
			scene._process(scene.STEP_SECONDS)
		elif state.turn_phase == Turn.Phase.WAITING_FOR_PATH:
			_check(scene.get_node("UI/Roll").disabled, "选路时掷骰按钮禁用")
			await _click(scene, "Choices/" + String(state.legal_exits[0]))
		else:
			return
	_check(false, "界面移动必须在有限步数内结束")


func _capture(scene, filename: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_check(not image.is_empty() and image.save_png("res://.godot/" + filename) == OK, "保存实际渲染截图: " + filename)
	# 同时检查当前全部 HUD 文本能容纳于其控件，不用截图掩盖溢出。
	for child in scene.get_node("UI").get_children():
		if child is Label:
			_check(child.get_minimum_size().x <= child.size.x and child.get_minimum_size().y <= child.size.y, "HUD 文字完整容纳: " + child.name)


func _check_layout(scene) -> void:
	var viewport := Rect2(Vector2.ZERO, Vector2(1152, 896))
	var token_rects: Array[Rect2] = []
	var colors: Array[Color] = []
	for index in range(4):
		_check(not colors.has(scene.PLAYER_COLORS[index]), "每个玩家有不同色块")
		colors.append(scene.PLAYER_COLORS[index])
	for tile in Route.get_tiles():
		var label := scene.get_node("Board/" + String(tile.id)) as Label
		_check(label != null and viewport.encloses(label.get_rect()), "完整路线在视口内: " + String(tile.id))
		for index in range(4):
			var rect: Rect2 = scene._token_rect(tile.id, index)
			_check(viewport.encloses(rect) and rect.position == Vector2(Vector2i(rect.position)), "玩家标记整数坐标且在视口内")
			_check(not rect.intersects(label.get_rect()), "玩家标记不遮挡格子 ID 或类型")
			for previous in token_rects:
				_check(not previous.intersects(rect), "同格及相邻格玩家标记不重叠")
			token_rects.append(rect)
	for child in scene.get_node("UI").get_children():
		if child is Control:
			_check(viewport.encloses(child.get_rect()), "控件位于视口内: " + child.name)
			_check(int(child.position.x) % 16 == 0 and int(child.position.y) % 16 == 0, "控件对齐 16px 网格")


func _run() -> void:
	var normal := GameScene.instantiate()
	normal.set_process(false)
	root.add_child(normal)
	_check(not normal._game.get_snapshot().test_controls, "正常入口默认随机骰子")
	_check(normal.get_node_or_null("UI/Test1") == null, "正常入口不显示测试控件")
	_check(normal.get_node("UI/NextAction").text.contains("CLICK START"), "未开局提供开始提示")
	_check(normal.get_node("UI/Restart").disabled, "未获胜不能重开")
	_check_layout(normal)
	await _capture(normal, "game_setup.png")
	await _click(normal, "Start3")
	_check(normal._game.get_snapshot().players.size() == 3, "界面选择三人")
	_check(normal.get_node("UI/NextAction").text.contains("CLICK ROLL"), "待掷骰提供明确文字提示")
	_check(normal.get_node("UI/Status").text.contains("DICE -"), "待掷骰不把上一回合结果当作本次结果")
	_check(normal.get_node("UI/Player1").text.contains("CURRENT"), "当前玩家有文字标记")
	await _click(normal, "Roll")
	var before: Dictionary = normal._game.get_snapshot()
	normal.get_node("UI/Roll").pressed.emit()
	_check(normal._game.get_snapshot() == before, "即使强制重复发出掷骰信号也不重掷")
	normal.set_process(true)
	var deadline: int = Time.get_ticks_msec() + 3000
	while normal._game.get_snapshot().turn_phase == Turn.Phase.MOVING and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(normal._game.get_snapshot().turn_phase != Turn.Phase.MOVING, "引擎实际帧计时能自动走到落点或岔路")
	normal.set_process(false)
	await _drain_ui(normal)
	normal.queue_free()
	await process_frame

	var four := GameScene.instantiate()
	four.test_controls_enabled = true
	four.set_process(false)
	root.add_child(four)
	await _click(four, "Start4")
	_check(four._game.get_snapshot().players.size() == 4, "界面选择四人")
	await _click(four, "Test6")
	_check(four.get_node("UI/NextAction").text.contains("PLEASE WAIT"), "移动阶段明确提示等待")
	four._process(four.STEP_SECONDS)
	four._process(four.STEP_SECONDS)
	_check(four._game.get_snapshot().turn_phase == Turn.Phase.WAITING_FOR_PATH, "界面停在岔路")
	_check(four.get_node("UI/Choices").get_child_count() == 2, "只生成两个合法出口按钮")
	_check(four.get_node("UI/NextAction").text.contains("CHOOSE AN EXIT"), "选路阶段明确提示出口操作")
	_check(four.get_node("UI/Restart").disabled, "等待选路期间不能覆盖对局")
	await _capture(four, "game_branch.png")
	var stale_choice: Callable = four.get_node("UI/Choices/a01").pressed.get_connections()[0].callable
	await _click(four, "Choices/a01")
	before = four._game.get_snapshot()
	stale_choice.call()
	_check(four._game.get_snapshot() == before, "旧分支按钮重复调用无副作用")
	await _drain_ui(four)
	_check(four._game.get_snapshot().current_player_index == 1, "界面移动完切换第二人")
	_check("\n".join(four._game.get_snapshot().logs).contains("CHOSE FORK TO A01"), "日志记录主动选路")
	# 当前第二人出生到中心，余额为零，界面必须说明不能兑换的原因。
	await _click(four, "Test6")
	await _drain_ui(four)
	await _click(four, "Test1")
	await _drain_ui(four)
	# 上面轮到玩家 3；让每人前进到 merge 后再由玩家 2 走一步进中心。
	for attempt in range(4):
		if four._game.get_snapshot().current_player_index == 1:
			break
		await _click(four, "Test6")
		await _drain_ui(four)
	await _click(four, "Test1")
	await _drain_ui(four)
	_check(four.get_node("UI/NextAction").text.contains("NEED 20 MONEY / HAVE 0"), "资金不足时提供具体原因")
	_check(four.get_node("UI/Exchange").disabled and not four.get_node("UI/Skip").disabled, "不足费用仅能放弃")
	await _capture(four, "game_insufficient.png")
	four.queue_free()
	await process_frame

	var scene := GameScene.instantiate()
	scene.test_controls_enabled = true
	scene.set_process(false)
	root.add_child(scene)
	await _click(scene, "Start2")
	var stale_start: Callable = scene.get_node("UI/Start2").pressed.get_connections()[0].callable
	var stale_roll: Callable
	var stale_exchange: Callable
	var stale_path: Callable
	var stale_restart: Callable
	var captured_exchange := false
	var third_star := false
	for turn_index in range(200):
		var state: Dictionary = scene._game.get_snapshot()
		if state.is_finished:
			break
		var actor: int = state.current_player_index
		if not stale_roll.is_valid():
			stale_roll = scene.get_node("UI/Test1").pressed.get_connections()[0].callable
		await _click(scene, "Test1")
		if scene._game.get_snapshot().turn_phase == Turn.Phase.WAITING_FOR_PATH and not stale_path.is_valid():
			stale_path = scene.get_node("UI/Choices/a01").pressed.get_connections()[0].callable
		await _drain_ui(scene)
		state = scene._game.get_snapshot()
		if state.turn_phase == Turn.Phase.WAITING_FOR_EXCHANGE:
			_check(scene.get_node("UI/Roll").disabled, "兑换时不能掷骰")
			if not captured_exchange:
				stale_exchange = scene.get_node("UI/Exchange").pressed.get_connections()[0].callable
				await _capture(scene, "game_exchange.png")
				captured_exchange = true
			if actor == 1:
				await _click(scene, "Exchange")
				state = scene._game.get_snapshot()
				if state.players[1].stars == 3:
					third_star = true
					_check(not state.is_finished, "界面购买第三星后仍继续")
					_check(scene.get_node("UI/Rules").text.contains("LAND ON CENTER AGAIN TO WIN"), "第三星后仍能看到返抵规则")
					_check(scene.get_node("UI/Player2").text.contains("STARS 3"), "即时更新第三星")
			else:
				await _click(scene, "Skip")
	var finished: Dictionary = scene._game.get_snapshot()
	_check(third_star and finished.is_finished and finished.winner_index == 1, "通过实际按钮完成从零开局到玩家 2 获胜")
	_check(scene.get_node("UI/Status").text.contains("P2 WINS"), "界面显示赢家")
	_check(scene.get_node("UI/Status").text.contains("DICE 1 / REMAINING STEPS 0"), "结束后仍显示最终骰子与余步")
	_check(scene.get_node("UI/Roll").disabled and scene.get_node("UI/Exchange").disabled and scene.get_node("UI/Skip").disabled, "胜利后操作按钮禁用")
	_check(not scene.get_node("UI/Restart").disabled and scene.get_node("UI/NextAction").text.contains("CLICK NEW GAME"), "胜利后明确引导重开")
	var rules_text: String = scene.get_node("UI/Rules").text
	_check(rules_text.contains("%d MONEY FOR 1 STAR" % Rules.STAR_COST) and rules_text.contains("GOAL: %d STARS" % Rules.TARGET_STARS), "费用和目标来自集中配置")
	before = scene._game.get_snapshot()
	scene._process(10.0)
	scene.get_node("UI/Roll").pressed.emit()
	scene.get_node("UI/Exchange").pressed.emit()
	scene.get_node("UI/Skip").pressed.emit()
	_check(scene._game.get_snapshot() == before, "胜利后计时回调与重复按钮不能推进流程")
	await _capture(scene, "game_win.png")
	stale_restart = scene.get_node("UI/Restart").pressed.get_connections()[0].callable
	await _click(scene, "Restart")
	var reset: Dictionary = scene._game.get_snapshot()
	_check(reset.players.is_empty() and reset.logs.is_empty() and reset.legal_exits.is_empty(), "重开清空玩家、日志与待选出口")
	_check(reset.current_player_index == -1 and reset.winner_index == -1 and not reset.is_finished, "重开清空当前人和赢家")
	_check(reset.last_roll == 0 and reset.remaining_steps == 0 and reset.turn_number == 0 and reset.stop_visit_id == -1, "重开清空骰子、余步、回合与待兑换编号")
	_check(scene.get_node("UI/Log").text.is_empty() and scene.get_node("UI/Choices").get_child_count() == 0, "旧日志和出口按钮从界面移除")
	for index in range(1, 5):
		_check(scene.get_node("UI/Player%d" % index).text.is_empty(), "重开清空所有玩家 HUD")
	for count in [2, 3, 4]:
		_check(not scene.get_node("UI/Start%d" % count).disabled, "重开可重新选择人数")
	for action in [stale_start, stale_roll, stale_exchange, stale_path, stale_restart]:
		_check(action.is_valid(), "保留的旧局回调有效，能验证其被拒绝")
		if action.is_valid():
			action.call()
	_check(scene._game.get_snapshot() == reset, "旧局按钮不能修改新局初始状态")
	scene._process(10.0)
	_check(scene._game.get_snapshot() == reset, "旧移动计时不会推进新局")
	await _capture(scene, "game_restart.png")
	await _click(scene, "Start4")
	var fresh: Dictionary = scene._game.get_snapshot()
	_check(fresh.players.size() == 4 and fresh.current_player_index == 0 and fresh.turn_number == 1, "获胜后可以改为四人重新开局")
	_check(fresh.logs == PackedStringArray(["START 4 PLAYERS"]), "新局日志只包含本次开局")
	for player in fresh.players:
		_check(player == {"position": Rules.SPAWN_TILE_ID, "money": 0, "stars": 0}, "新玩家均回到初始位置、金钱和星数")
	for action in [stale_roll, stale_exchange, stale_path]:
		action.call()
	_check(scene._game.get_snapshot() == fresh, "旧局请求即使等待编号再次出现也无效")
	await _click(scene, "Test1")
	await _drain_ui(scene)
	_check(scene._game.get_snapshot().players[0].money == Rules.COIN_REWARD, "新局可以继续完整回合")
	print("game_ui: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
