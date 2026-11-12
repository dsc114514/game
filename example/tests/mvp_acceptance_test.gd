extends SceneTree
## 从配置中的 F5 场景通过鼠标输入验收；移动仅由引擎正常帧推进。
## 不调用规则操作、_process、判胜方法，也不改写玩家状态或引擎时间。

const Turn = preload("res://example/gameplay/turn_controller.gd")
const Rules = preload("res://example/gameplay/mvp_rules.gd")
const REPORT_PATH := "res://.godot/mvp_acceptance.jsonl"

var _checks: int = 0
var _failures: int = 0
var _report: FileAccess
var _started_at: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)


func _record(event: String, scene = null, detail: Dictionary = {}) -> void:
	var row := {"event": event, "elapsed_ms": Time.get_ticks_msec() - _started_at, "detail": detail}
	if scene != null:
		row["state"] = scene._game.get_snapshot()
	if _report != null:
		_report.store_line(JSON.stringify(row))
		_report.flush()
	if event != "turn":
		print("acceptance: ", event, " ", JSON.stringify(detail))


func _new_scene():
	var entry: String = ProjectSettings.get_setting("application/run/main_scene", "")
	_check(entry == "res://example/board/game.tscn", "验收实际配置的 F5 入口")
	var scene = load(entry).instantiate()
	# 复用现有显式测试骰子控件；不替换控制器或路线。
	scene.test_controls_enabled = true
	root.add_child(scene)
	await process_frame
	_check(scene.is_processing() and Engine.time_scale == 1.0, "移动使用正常引擎帧和原始时间倍率")
	return scene


func _click(scene, path: String, times: int = 1, enabled: bool = true) -> void:
	await process_frame
	var button := scene.get_node("UI/" + path) as Button
	_check(button != null and button.disabled != enabled, "按钮启用状态: " + path)
	if button == null:
		return
	var point := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	for index in range(times):
		for pressed in [true, false]:
			var event := InputEventMouseButton.new()
			event.button_index = MOUSE_BUTTON_LEFT
			event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
			event.position = point
			event.global_position = point
			event.pressed = pressed
			root.push_input(event, true)
	await process_frame


func _wait_for_landing(scene, choice: String = "a01") -> bool:
	var deadline := Time.get_ticks_msec() + 5000
	while Time.get_ticks_msec() < deadline:
		var state: Dictionary = scene._game.get_snapshot()
		if state.turn_phase == Turn.Phase.WAITING_FOR_PATH:
			_check(scene.get_node("UI/Roll").disabled and scene.get_node("UI/Exchange").disabled, "岔路只允许选路")
			var actor: int = state.current_player_index
			await create_timer(0.22).timeout
			_check(scene._game.get_snapshot() == state, "等待选路不自动移动、结算或换人")
			await _click(scene, "Choices/" + choice, 2)
			var after: Dictionary = scene._game.get_snapshot()
			_check(after.players[actor].position == StringName(choice), "重复点击出口只前进一格")
			_check(after.remaining_steps == state.remaining_steps - 1, "选路只消耗一步")
			_record("branch", scene, {"player": actor + 1, "target": choice})
		elif state.turn_phase == Turn.Phase.MOVING:
			_check(scene.get_node("UI/Roll").disabled, "引擎移动时禁用掷骰")
			await process_frame
		else:
			return true
	_check(false, "真实计时移动在五秒内到落点，不能界面阻塞")
	return false


func _roll_and_land(scene, value: int, choice: String = "a01") -> bool:
	var state: Dictionary = scene._game.get_snapshot()
	_check(state.turn_phase == Turn.Phase.WAITING_FOR_ROLL, "当前玩家等待掷骰")
	await _click(scene, "Test%d" % value, 2)
	var rolled: Dictionary = scene._game.get_snapshot()
	_check(rolled.last_roll == value and rolled.remaining_steps <= value, "指定点数生效且重复点击不累加步数")
	return await _wait_for_landing(scene, choice)


func _capture(filename: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_check(not image.is_empty() and image.save_png("res://.godot/" + filename) == OK, "保存验收画面: " + filename)


func _test_player_counts() -> void:
	for count in [2, 3, 4]:
		var scene = await _new_scene()
		await _click(scene, "Start%d" % count, 2)
		var initial: Dictionary = scene._game.get_snapshot()
		_check(initial.players.size() == count and initial.current_player_index == 0 and initial.turn_number == 1, "%d 人开局与首位正确" % count)
		for player in initial.players:
			_check(player == {"position": Rules.SPAWN_TILE_ID, "money": 0, "stars": 0}, "初始位置、金钱和星数正确")
		var order: Array[int] = []
		for index in range(count * 2):
			var before: Dictionary = scene._game.get_snapshot()
			order.append(before.current_player_index + 1)
			if not await _roll_and_land(scene, 1):
				break
			var after: Dictionary = scene._game.get_snapshot()
			_check(after.current_player_index == (index + 1) % count and after.turn_number == index + 2, "两轮按编号轮换并回到首位")
			_check(after.players[index % count].money == 10, "金币落点只奖励一次，后续岔路无奖")
		_check(scene.get_node("UI/Choices").get_child_count() == 0, "恰好停在岔路无需选择")
		_record("player_count", scene, {"count": count, "order": order})
		scene.queue_free()
		await process_frame


func _test_insufficient_money() -> void:
	var scene = await _new_scene()
	await _click(scene, "Start2")
	for choice in ["a01", "b01"]:
		if not await _roll_and_land(scene, 6, choice):
			return
	_check(scene._game.get_snapshot().players[0].money == 0 and scene._game.get_snapshot().players[1].money == 0, "经过金币格没有奖励")
	if not await _roll_and_land(scene, 1):
		return
	var waiting: Dictionary = scene._game.get_snapshot()
	_check(waiting.players[0].position == Rules.STOP_TILE_ID and waiting.current_player_index == 0, "准确落到中心并保持当前人")
	_check(scene.get_node("UI/NextAction").text.contains("NEED 20 MONEY / HAVE 0"), "余额不足显示金额和下一步")
	await _click(scene, "Exchange", 2, false)
	await _click(scene, "Roll", 2, false)
	_check(scene._game.get_snapshot() == waiting, "点击禁用兑换和掷骰无副作用")
	await _capture("acceptance_insufficient.png")
	await _click(scene, "Skip", 2)
	var after: Dictionary = scene._game.get_snapshot()
	_check(after.current_player_index == 1 and after.players[0].money == 0 and after.players[0].stars == 0, "重复放弃只结束一次回合且不改变资源")
	_record("insufficient_and_skip", scene)
	scene.queue_free()
	await process_frame


func _test_complete_game() -> void:
	var scene = await _new_scene()
	await _capture("acceptance_setup.png")
	await _click(scene, "Start2")
	_record("complete_game_start", scene)
	var third_purchase := false
	var left_after_third := false
	var purchases: int = 0
	for index in range(160):
		var before: Dictionary = scene._game.get_snapshot()
		if before.is_finished:
			break
		var actor: int = before.current_player_index
		if not await _roll_and_land(scene, 1):
			return
		var state: Dictionary = scene._game.get_snapshot()
		if third_purchase and actor == 1 and state.players[1].position != Rules.STOP_TILE_ID and not left_after_third:
			left_after_third = true
			_record("left_center_after_third", scene)
		if state.turn_phase == Turn.Phase.WAITING_FOR_EXCHANGE:
			await create_timer(0.22).timeout
			_check(scene._game.get_snapshot() == state, "停留决策期间不自动换人")
			if actor == 1:
				var old_money: int = state.players[1].money
				await _click(scene, "Exchange", 2)
				state = scene._game.get_snapshot()
				purchases += 1
				_check(state.players[1].stars == purchases and state.players[1].money == old_money - Rules.STAR_COST, "重复兑换只扣一次费用并增加一星")
				_check(state.current_player_index == 0 and not state.is_finished, "兑换后结束当前回合，不立即获胜")
				_record("purchase", scene, {"number": purchases, "turn": before.turn_number, "money_before": old_money})
				if purchases == Rules.TARGET_STARS:
					third_purchase = true
			else:
				var before_skip: Dictionary = state.players[0].duplicate()
				await _click(scene, "Skip", 2)
				state = scene._game.get_snapshot()
				_check(state.players[0] == before_skip and state.current_player_index == 1, "放弃不改变资源和位置，且只轮换一次")
		_record("turn", scene, {"actor": actor + 1, "turn": before.turn_number})
	var finished: Dictionary = scene._game.get_snapshot()
	_check(third_purchase and left_after_third, "购买第三星后实际离开中心")
	_check(finished.is_finished and finished.winner_index == 1 and finished.current_player_index == 1, "返抵中心获胜且不切换玩家")
	_check(finished.players[1] == {"position": Rules.STOP_TILE_ID, "money": 170, "stars": 3}, "完整路线积分和最终资源一致，胜利不扣费")
	_check(finished.turn_number == 134, "完整对局经过真实的 134 个回合")
	_check(scene.get_node("UI/Status").text.contains("P2 WINS"), "画面明确显示获胜者")
	_record("win", scene)
	for path in ["Roll", "Exchange", "Skip", "Start2", "Start3", "Start4", "Test1", "Test2", "Test3", "Test4", "Test5", "Test6"]:
		await _click(scene, path, 2, false)
	await create_timer(0.3).timeout
	_check(scene._game.get_snapshot() == finished, "胜利后所有对局按钮和正常帧均不能改变状态")
	_check(scene.get_node("UI/Choices").get_child_count() == 0, "胜利后没有待选路线")
	_record("finished_frozen", scene)
	await _click(scene, "Restart", 2)
	var reset: Dictionary = scene._game.get_snapshot()
	_check(reset.players.is_empty() and reset.logs.is_empty() and reset.legal_exits.is_empty(), "重开清空玩家、日志、出口")
	_check(reset.last_roll == 0 and reset.remaining_steps == 0 and reset.turn_number == 0 and reset.input_id == 0 and reset.stop_visit_id == -1, "重开清空骰子、步数、回合与待处理编号")
	_check(reset.current_player_index == -1 and reset.winner_index == -1 and not reset.is_finished, "重开清空当前玩家与赢家")
	_check(scene.get_node("UI/Log").text.is_empty() and scene.get_node("UI/Choices").get_child_count() == 0 and scene._elapsed == 0.0, "重开清空画面、待处理选择和计时")
	await _click(scene, "Start4")
	var fresh: Dictionary = scene._game.get_snapshot()
	_check(fresh.logs == PackedStringArray(["START 4 PLAYERS"]), "新局日志只包含新开局")
	for player in fresh.players:
		_check(player == {"position": Rules.SPAWN_TILE_ID, "money": 0, "stars": 0}, "新局每名玩家资源与位置复位")
	if await _roll_and_land(scene, 1):
		var continued: Dictionary = scene._game.get_snapshot()
		_check(continued.players.size() == 4 and continued.current_player_index == 1 and continued.players[0].money == 10, "重新开局后四人对局能继续")
	_record("restart_and_continue", scene)
	scene.queue_free()
	await process_frame


func _run() -> void:
	_started_at = Time.get_ticks_msec()
	_report = FileAccess.open(REPORT_PATH, FileAccess.WRITE)
	_check(_report != null, "可以保存验收过程记录")
	_record("environment", null, {"godot": Engine.get_version_info().string, "display": DisplayServer.get_name(), "main_scene": ProjectSettings.get_setting("application/run/main_scene"), "time_scale": Engine.time_scale})
	await _test_player_counts()
	await _test_insufficient_money()
	await _test_complete_game()
	_record("result", null, {"checks": _checks, "failures": _failures})
	if _report != null:
		_report.close()
	print("mvp_acceptance: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
