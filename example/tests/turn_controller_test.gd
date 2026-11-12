extends SceneTree
## 通过真实路线从零开局到胜利，不直接写入玩家资金、位置或星数。

const Turn = preload("res://example/gameplay/turn_controller.gd")
const Rules = preload("res://example/gameplay/mvp_rules.gd")

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_test_start_and_roll()
	_test_context_and_seed()
	_test_movement_and_landing()
	_test_branches()
	_test_consecutive_branches()
	_test_rotation_and_exchange()
	_test_complete_game()
	_test_pass_center_after_target()
	print("turn_controller: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)


func _new_game(count: int = 2):
	var game = Turn.new(true)
	_check(game.start_game(count), "%d 人开局" % count)
	return game


func _roll(game, value: int) -> int:
	var input_id: int = game.get_snapshot().input_id
	_check(game.roll_for_test(value, input_id), "指定骰子 %d" % value)
	return input_id


func _drain(game, choice: StringName = &"a01") -> void:
	for step in range(16):
		var state: Dictionary = game.get_snapshot()
		if state.turn_phase == Turn.Phase.MOVING:
			_check(game.advance(game.get_snapshot().input_id), "沿连接前进一步")
		elif state.turn_phase == Turn.Phase.WAITING_FOR_PATH:
			var target: StringName = choice if state.legal_exits.has(choice) else StringName(state.legal_exits[0])
			_check(game.choose_path(target, state.input_id), "选择合法岔路")
		else:
			return
	_check(false, "移动必须在有限步数内停止")


func _turn(game, value: int, choice: StringName = &"a01") -> void:
	_roll(game, value)
	_drain(game, choice)


func _test_start_and_roll() -> void:
	var game = Turn.new(true)
	var before: Dictionary = game.get_snapshot()
	_check(not game.advance(game.get_snapshot().input_id), "未开局不能移动")
	_check(not game.roll_dice(before.input_id), "未开局不能掷骰")
	_check(not game.choose_path(&"a01", before.input_id), "未开局不能选路")
	_check(not game.exchange_star(before.input_id), "未开局不能兑换")
	_check(not game.skip_exchange(before.input_id), "未开局不能放弃兑换")
	for count in [0, 1, 5]:
		_check(not game.start_game(count), "拒绝非法人数")
	_check(game.get_snapshot() == before, "无效操作不改变未开局状态")
	_check(game.start_game(2), "合法开局")
	before = game.get_snapshot()
	_check(not game.start_game(3), "不能覆盖进行中的对局")
	for value in [0, 7, -1]:
		_check(not game.roll_for_test(value, before.input_id), "拒绝超范围测试骰子")
	_check(not game.roll_dice(before.input_id - 1), "拒绝过期掷骰请求")
	_check(game.get_snapshot() == before, "无效骰子请求无副作用")
	var old_input := _roll(game, 2)
	before = game.get_snapshot()
	_check(before.last_roll == 2 and before.remaining_steps == 2, "掷骰只设置一次步数")
	_check(not game.roll_for_test(6, old_input), "移动中不能重掷指定骰子")
	_check(not game.roll_dice(old_input), "移动中不能重掷随机骰子")
	_check(game.get_snapshot() == before, "重复掷骰无副作用")
	_drain(game)
	before = game.get_snapshot()
	_check(not game.roll_dice(old_input), "换人后旧掷骰请求仍然无效")
	_check(game.get_snapshot() == before, "过期请求不能替下一位掷骰")
	var snapshot: Dictionary = game.get_snapshot()
	snapshot.players[0].money = 999
	snapshot.logs.append("FAKE")
	_check(game.get_snapshot() == before, "快照修改不能改变玩家或日志")
	# 正常模式不开放指定结果；随机骰子始终处于配置范围。
	var normal = Turn.new(false, [], 20261112)
	_check(normal.start_game(2), "正常模式开局")
	before = normal.get_snapshot()
	_check(not normal.roll_for_test(6, before.input_id), "默认禁用测试骰子")
	_check(normal.get_snapshot() == before, "测试入口禁用时不改变状态")
	var random_rolls: Array[int] = []
	for index in range(40):
		_check(normal.roll_dice(normal.get_snapshot().input_id), "正常随机掷骰")
		var result: int = normal.get_snapshot().last_roll
		random_rolls.append(result)
		_check(result >= Rules.DICE_MIN and result <= Rules.DICE_MAX, "随机骰子范围正确")
		_drain(normal)
		if normal.get_snapshot().turn_phase == Turn.Phase.WAITING_FOR_EXCHANGE:
			_check(normal.skip_exchange(normal.get_snapshot().input_id), "随机对局可放弃兑换继续")
	print("rule random trace: seed=20261112 dice=%s choices=a01 exchanges=skip" % str(random_rolls))
	var invalid = Turn.new(true, [{"id": "spawn", "type": "spawn", "next": ["missing"]}])
	_check(not invalid.get_snapshot().errors.is_empty() and not invalid.start_game(2), "坏路线阻止开局并提供错误")


func _test_context_and_seed() -> void:
	# 同一局的移动步编号随每一步变化；旧计时回调不能重复推进。
	var game = _new_game()
	_roll(game, 3)
	var old_step_input: int = game.get_snapshot().input_id
	_check(game.advance(old_step_input), "带当前步编号移动")
	var after_step: Dictionary = game.get_snapshot()
	_check(not game.advance(old_step_input), "旧步编号不能重复推进")
	_check(game.get_snapshot() == after_step, "旧步编号拒绝时状态不变")

	# 新控制器的同阶段编号不能接受旧局输入。
	var old_game = _new_game()
	var stale_input: int = old_game.get_snapshot().input_id
	var fresh_game = _new_game()
	var fresh_before: Dictionary = fresh_game.get_snapshot()
	_check(not fresh_game.roll_for_test(1, stale_input), "旧局编号不能作用于新局")
	_check(fresh_game.get_snapshot() == fresh_before, "旧局编号拒绝时新局状态不变")
	_roll(old_game, 3)
	_roll(fresh_game, 3)
	fresh_before = fresh_game.get_snapshot()
	_check(not fresh_game.advance(old_game.get_snapshot().input_id), "旧局计时编号不能推进新局")
	_check(fresh_game.get_snapshot() == fresh_before, "旧局计时被拒绝后新局不变")

	# 固定种子复现同一随机骰子序列；被拒绝的请求不消耗随机序列。
	var seeded_a = Turn.new(false, [], 123456)
	var seeded_b = Turn.new(false, [], 123456)
	_check(seeded_a.start_game(2) and seeded_b.start_game(2), "固定种子对局开局")
	_check(seeded_a.get_snapshot().random_seed == 123456 and seeded_b.get_snapshot().random_seed == 123456, "快照记录固定种子")
	var dice_sequence: Array[int] = []
	for index in range(12):
		var a_before: Dictionary = seeded_a.get_snapshot()
		var b_before: Dictionary = seeded_b.get_snapshot()
		_check(not seeded_a.roll_dice(b_before.input_id), "另一局随机请求被拒绝")
		_check(seeded_a.get_snapshot() == a_before, "非法随机请求不改状态")
		_check(seeded_a.roll_dice(a_before.input_id) and seeded_b.roll_dice(b_before.input_id), "固定种子随机掷骰")
		_check(seeded_a.get_snapshot().last_roll == seeded_b.get_snapshot().last_roll, "相同种子骰子序列一致")
		dice_sequence.append(seeded_a.get_snapshot().last_roll)
		_drain(seeded_a)
		_drain(seeded_b)
		if seeded_a.get_snapshot().turn_phase == Turn.Phase.WAITING_FOR_EXCHANGE:
			_check(seeded_a.skip_exchange(seeded_a.get_snapshot().input_id), "固定种子对局 A 继续")
			_check(seeded_b.skip_exchange(seeded_b.get_snapshot().input_id), "固定种子对局 B 继续")
	print("rule seed trace: seed=123456 dice=%s choices=a01 exchanges=skip" % str(dice_sequence))
	var invalid_seed = Turn.new(false, [], "not a seed")
	_check(not invalid_seed.start_game(2) and not invalid_seed.get_snapshot().errors.is_empty(), "非法种子明确诊断并拒绝开局")


func _test_movement_and_landing() -> void:
	var game = _new_game()
	_roll(game, 1)
	_check(game.get_snapshot().players[0].position == &"spawn", "掷骰尚未移动")
	_check(game.advance(game.get_snapshot().input_id), "一条连接消耗一步")
	var state: Dictionary = game.get_snapshot()
	_check(state.remaining_steps == 0 and state.players[0].position == &"c01", "一步落在 c01")
	_check(state.players[0].money == Rules.COIN_REWARD, "金币落点加钱")
	_check(state.current_player_index == 1 and state.turn_phase == Turn.Phase.WAITING_FOR_ROLL, "落点自动轮换")
	_check(not game.advance(game.get_snapshot().input_id), "结算后重复推进无效")
	game._settle_landing()
	_check(game.get_snapshot() == state, "重复结算不能再次加钱或轮换")
	# 出生→金币→岔路恰好两步：路过金币无奖励，岔路落点无需选路。
	var fork_game = _new_game()
	_turn(fork_game, 2)
	state = fork_game.get_snapshot()
	_check(state.players[0].position == &"fork" and state.players[0].money == 0, "恰好停在岔路且路过金币不加钱")
	_check(state.legal_exits.is_empty() and state.current_player_index == 1, "零步不等待未使用的出口")
	_turn(fork_game, 1)
	_roll(fork_game, 1)
	state = fork_game.get_snapshot()
	_check(state.turn_phase == Turn.Phase.WAITING_FOR_PATH and state.remaining_steps == 1, "下一回合从岔路出发才要求选路")
	_check(fork_game.choose_path(&"a01", state.input_id), "选路本身沿连接消耗一步")
	_check(fork_game.get_snapshot().players[0].money == Rules.COIN_REWARD, "选路最后一步直接落点结算")
	# 停留点之后一格是金币，跨过它落到商店时不发钱。
	var shop_game = _new_game()
	_turn(shop_game, 6)
	_turn(shop_game, 6, &"b01")
	_turn(shop_game, 1)
	state = shop_game.get_snapshot()
	_check(state.players[0].position == Rules.STOP_TILE_ID and state.turn_phase == Turn.Phase.WAITING_FOR_EXCHANGE, "恰好停在停留点")
	_check(state.current_player_index == 0 and state.remaining_steps == 0, "等待兑换时不轮换")
	_check(not shop_game.exchange_star(state.input_id), "余额不足不能兑换")
	_check(shop_game.get_snapshot() == state, "余额不足保留当前停留决策")
	_check(shop_game.skip_exchange(state.input_id), "余额不足仍可放弃")
	_turn(shop_game, 3)
	state = shop_game.get_snapshot()
	_check(state.players[1].position == &"shop02" and state.players[1].money == 0, "路过中心与金币，落在商店仅记录日志")
	_check("\n".join(state.logs).contains("SHOP SHOP02 / LOG ONLY"), "商店日志存在")
	_turn(shop_game, 3)
	state = shop_game.get_snapshot()
	_check(state.players[0].position == &"event02" and state.players[0].money == 0, "事件格不改变资金")
	_check("\n".join(state.logs).contains("EVENT EVENT02 / LOG ONLY"), "事件日志存在")


func _test_branches() -> void:
	var game = _new_game()
	var roll_input := _roll(game, 6)
	_check(game.advance(game.get_snapshot().input_id) and game.advance(game.get_snapshot().input_id), "前两步抵达岔路")
	var waiting: Dictionary = game.get_snapshot()
	_check(waiting.players[0].position == &"fork" and waiting.remaining_steps == 4, "到岔路保留剩余四步")
	_check(waiting.turn_phase == Turn.Phase.WAITING_FOR_PATH and waiting.current_player_index == 0, "等待玩家选路")
	_check(not game.advance(game.get_snapshot().input_id), "等待选路不能自动继续")
	_check(not game.roll_dice(waiting.input_id), "等待选路不能重掷骰")
	_check(not game.choose_path(&"center", waiting.input_id), "拒绝非出口目标")
	_check(not game.choose_path(&"a01", roll_input), "拒绝旧等待编号")
	_check(game.get_snapshot() == waiting, "等待期间无效操作不改变状态")
	_check(game.choose_path(&"a01", waiting.input_id), "上分支选择成功")
	var after: Dictionary = game.get_snapshot()
	_check(after.remaining_steps == 3 and after.last_roll == 6 and after.players[0].position == &"a01", "选路消耗一步且不重掷")
	_check(not game.choose_path(&"a01", waiting.input_id), "重复选路无效")
	_check(game.get_snapshot() == after, "重复选路不多走一步")
	_drain(game)
	_check(game.get_snapshot().players[0].position == &"merge", "六步最终落在汇合点")
	_check(game.get_snapshot().players[0].money == 0, "路过所有金币均不发奖")
	_turn(game, 6, &"b01")
	_check(game.get_snapshot().players[1].position == &"merge", "下分支也在同样步数汇合")
	_check(game.get_snapshot().players[0].position == game.get_snapshot().players[1].position, "多人同格不触发战斗")


func _test_consecutive_branches() -> void:
	var fixture: Array = [
		{"id": "spawn", "type": "spawn", "next": ["fork1"]},
		{"id": "fork1", "type": "branch", "next": ["fork2", "coin"]},
		{"id": "fork2", "type": "branch", "next": ["coin", "center"]},
		{"id": "coin", "type": "coin", "next": ["center"]},
		{"id": "center", "type": "stop", "next": ["spawn"]},
	]
	var game = Turn.new(true, fixture)
	_check(game.start_game(2), "连续岔路小型测试路线开局")
	_roll(game, 4)
	_check(game.advance(game.get_snapshot().input_id), "走到第一个岔路")
	var first: Dictionary = game.get_snapshot()
	_check(game.choose_path(&"fork2", first.input_id), "进入紧邻的第二个岔路")
	var second: Dictionary = game.get_snapshot()
	_check(second.turn_phase == Turn.Phase.WAITING_FOR_PATH and second.remaining_steps == 2, "连续岔路第二次暂停，步数正确")
	_check(second.input_id != first.input_id and second.current_player_index == 0, "同回合新岔路使用新编号")
	_check(not game.choose_path(&"coin", first.input_id), "即使目标也是合法出口，旧选择编号仍失效")
	_check(game.get_snapshot() == second, "旧分支选择不改变新岔路状态")
	_check(game.choose_path(&"coin", second.input_id), "第二次合法选择")
	_check(game.get_snapshot().remaining_steps == 1, "第二次选择再消耗一步")
	_check(game.advance(game.get_snapshot().input_id), "最后一步落在中心")
	var state: Dictionary = game.get_snapshot()
	_check(state.turn_phase == Turn.Phase.WAITING_FOR_EXCHANGE and state.players[0].money == 0, "路过币格不加钱且等待停留决策")
	_check(game.skip_exchange(state.input_id), "结束停留决策")
	_turn(game, 2)
	_check(game.get_snapshot().players[1].position == &"fork2", "恰好落在连续岔路的第二个节点不继续选路")
	_turn(game, 1)
	_check(game.get_snapshot().players[0].position == Rules.SPAWN_TILE_ID and game.get_snapshot().players[0].money == 0, "出生点落点无奖励")


func _test_rotation_and_exchange() -> void:
	for count in [2, 3, 4]:
		var game = _new_game(count)
		for round_index in range(2):
			for index in range(count):
				_check(game.get_snapshot().current_player_index == index, "%d 人顺序轮换 %d" % [count, index])
				_turn(game, 1)
		_check(game.get_snapshot().current_player_index == 0, "最后一人后回到第一人")
	var game = _new_game()
	# 每人每次只走一步，真实积累两次金币后首次落在中心。
	for round_index in range(7):
		for index in range(2):
			_turn(game, 1)
			var state: Dictionary = game.get_snapshot()
			if state.turn_phase == Turn.Phase.WAITING_FOR_EXCHANGE:
				_check(state.players[index].money == 20 and state.players[index].stars == 0, "初次到中心已从路线挣得 20")
				var input_id: int = state.input_id
				if index == 0:
					_check(game.exchange_star(input_id), "兑换结束当前回合")
					var after: Dictionary = game.get_snapshot()
					_check(after.players[0].money == 0 and after.players[0].stars == 1 and after.current_player_index == 1, "扣费加星后轮换")
					_check(not game.exchange_star(input_id) and not game.skip_exchange(input_id), "重复兑换或放弃不影响下一人")
					game._settle_landing()
					_check(game.get_snapshot() == after, "重复停留结算无副作用")
				else:
					_check(game.skip_exchange(input_id), "放弃兑换结束当前回合")
					_check(game.get_snapshot().players[1].money == 20 and game.get_snapshot().players[1].stars == 0, "放弃不扣钱、不加星")


func _test_complete_game() -> void:
	var game = _new_game()
	var third_purchase_seen := false
	var center_left_after_third := false
	for turn_index in range(200):
		var state: Dictionary = game.get_snapshot()
		if state.is_finished:
			break
		var actor: int = state.current_player_index
		_turn(game, 1)
		state = game.get_snapshot()
		if third_purchase_seen and actor == 1 and state.players[1].position != Rules.STOP_TILE_ID:
			center_left_after_third = true
		if state.turn_phase == Turn.Phase.WAITING_FOR_EXCHANGE:
			if actor == 1:
				_check(game.exchange_star(state.input_id), "玩家 2 用真实金币购星")
				state = game.get_snapshot()
				if state.players[1].stars == Rules.TARGET_STARS:
					third_purchase_seen = true
					_check(not state.is_finished and state.current_player_index == 0, "刚买第三星不获胜，正常轮换")
			else:
				_check(game.skip_exchange(state.input_id), "玩家 1 放弃兑换")
	var finished: Dictionary = game.get_snapshot()
	_check(third_purchase_seen and center_left_after_third, "达标后实际离开停留点")
	_check(finished.is_finished and finished.winner_index == 1, "从零开局经过完整路线最终玩家 2 获胜")
	_check(finished.current_player_index == 1 and finished.turn_phase == Turn.Phase.FINISHED, "获胜立即停在当前玩家")
	_check(finished.players[1].stars == 3 and finished.players[1].position == Rules.STOP_TILE_ID, "三颗星后再次落在中心")
	_check(finished.players[1].money == 170, "获胜前余额与路线落点奖励一致，胜利不扣兑换费")
	_check(not game.advance(game.get_snapshot().input_id), "结束后不能移动")
	_check(not game.roll_dice(finished.input_id), "结束后不能随机掷骰")
	_check(not game.roll_for_test(6, finished.input_id), "结束后不能指定骰子")
	_check(not game.choose_path(&"a01", finished.input_id), "结束后不能选路")
	_check(not game.exchange_star(finished.input_id), "结束后不能兑换")
	_check(not game.skip_exchange(finished.input_id), "结束后不能放弃或换人")
	_check(not game.start_game(4), "结束后不能覆盖当前对局")
	game._settle_landing()
	_check(game.get_snapshot() == finished, "所有结束后请求均无副作用")


func _test_pass_center_after_target() -> void:
	var game = _new_game()
	var passed_with_target := false
	for turn_index in range(240):
		var state: Dictionary = game.get_snapshot()
		if state.is_finished:
			break
		var actor: int = state.current_player_index
		var player: Dictionary = state.players[actor]
		if actor == 1 and player.stars == Rules.TARGET_STARS and player.position == &"merge" and not passed_with_target:
			var money_before: int = player.money
			_turn(game, 2)
			state = game.get_snapshot()
			_check(not state.is_finished and state.players[1].position == &"c02", "达标后路过中心不停止、不获胜")
			_check(state.players[1].money == money_before + Rules.COIN_REWARD, "路过中心不扣费，最终币格正常结算")
			passed_with_target = true
		else:
			_turn(game, 1)
		state = game.get_snapshot()
		if state.turn_phase == Turn.Phase.WAITING_FOR_EXCHANGE:
			if actor == 1:
				_check(game.exchange_star(state.input_id), "路过中心测试购星")
			else:
				_check(game.skip_exchange(state.input_id), "路过中心测试放弃兑换")
	var finished: Dictionary = game.get_snapshot()
	_check(passed_with_target and finished.is_finished and finished.winner_index == 1, "达标后先路过，再次准确落在中心才获胜")
