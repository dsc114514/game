extends SceneTree
## 无第三方依赖。失败时输出错误并以退出码 1 结束。

const MatchState = preload("res://example/gameplay/match_state.gd")
const Rules = preload("res://example/gameplay/mvp_rules.gd")

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	_test_initialization()
	_test_money()
	_test_exchange()
	_test_skip_and_stale_exchange()
	_test_return_and_finish()
	print("match_state: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)


func _land(game, tile_id: StringName) -> void:
	_check(game.move_current_player_to(tile_id), "移动到落点成功")
	_check(game.settle_landing(), "落点结算成功")


func _test_initialization() -> void:
	var game = MatchState.new()
	var before: Dictionary = game.get_snapshot()
	_check(before.players.is_empty(), "未开局时没有玩家")
	_check(before.current_player_index == -1 and before.winner_index == -1, "未开局没有当前玩家或赢家")
	_check(not game.change_money(0, 10), "未开局拒绝金钱变更")
	_check(not game.move_current_player_to(Rules.STOP_TILE_ID), "未开局拒绝移动")
	_check(not game.settle_landing(), "未开局拒绝结算")
	_check(not game.exchange_star(0), "未开局拒绝兑换")
	_check(not game.end_turn(), "未开局拒绝切换玩家")
	for count in [-1, 0, 1, 5, 100]:
		_check(not game.start_game(count), "拒绝非法人数 %d" % count)
		_check(game.get_snapshot() == before, "非法开局不改状态")
	for count in [2, 3, 4]:
		var match_game = MatchState.new()
		_check(match_game.start_game(count), "%d 人开局成功" % count)
		var state: Dictionary = match_game.get_snapshot()
		_check(state.players.size() == count, "人数正确")
		_check(state.current_player_index == 0 and not state.is_finished and state.winner_index == -1, "开局流程状态正确")
		for player in state.players:
			_check(player.size() == 3, "每名玩家只有位置、钱、星")
			_check(player.position == Rules.SPAWN_TILE_ID and player.money == 0 and player.stars == 0, "玩家初始值正确")
		_check(match_game.change_money(0, Rules.COIN_REWARD), "第一名玩家收款")
		_check(match_game.move_current_player_to(&"path"), "第一名玩家移动")
		state = match_game.get_snapshot()
		_check(state.players[0].money == Rules.COIN_REWARD, "第一名玩家金额正确")
		for index in range(1, count):
			_check(state.players[index] == {"position": Rules.SPAWN_TILE_ID, "money": 0, "stars": 0}, "其他玩家独立")
		state.players[0].money = 999
		state.players.clear()
		_check(match_game.get_snapshot().players.size() == count, "修改快照不影响玩家数组")
		_check(match_game.get_snapshot().players[0].money == Rules.COIN_REWARD, "修改快照不影响玩家数据")
		before = match_game.get_snapshot()
		_check(not match_game.start_game(count), "拒绝覆盖已开局对局")
		_check(match_game.get_snapshot() == before, "重复开局不改状态")
		_check(match_game.settle_landing(), "普通落点结算")
		for index in range(1, count):
			_check(match_game.end_turn(), "切换到下一位玩家")
			_check(match_game.get_snapshot().current_player_index == index, "按数组顺序轮换")
			_land(match_game, &"path")
		_check(match_game.end_turn(), "最后一人结束回合")
		_check(match_game.get_snapshot().current_player_index == 0, "轮换回第一位玩家")
	_check(game.get_snapshot().players.is_empty(), "各对局实例互相独立")


func _test_money() -> void:
	var game = MatchState.new()
	_check(game.start_game(2), "金钱验证开局")
	var before: Dictionary = game.get_snapshot()
	_check(not game.change_money(-1, 10), "拒绝负玩家索引")
	_check(not game.change_money(2, 10), "拒绝越界玩家索引")
	_check(not game.change_money(0, -1), "拒绝负余额")
	_check(game.get_snapshot() == before, "非法金额操作无副作用")
	_check(game.change_money(0, Rules.COIN_REWARD), "允许奖励金币")
	_check(game.change_money(0, -Rules.COIN_REWARD), "允许扣至零")
	_check(game.get_snapshot().players[0].money == 0, "收支恰好归零")
	_check(game.change_money(0, 9223372036854775807), "允许 int64 范围内余额")
	before = game.get_snapshot()
	_check(not game.change_money(0, 1), "拒绝 int64 加法溢出")
	_check(not game.change_money(0, -9223372036854775807 - 1), "拒绝 int64 最小值造成透支")
	_check(game.get_snapshot() == before, "溢出或透支不改状态")
	_check(game.change_money(0, -9223372036854775807), "允许扣除完整余额")
	_check(game.get_snapshot().players[0].money == 0, "大额收支归零")


func _test_exchange() -> void:
	var game = MatchState.new()
	_check(game.start_game(2), "兑换验证开局")
	_check(not game.exchange_star(0), "未到停留点不能兑换")
	_check(not game.settle_landing(), "未移动不能制造停留结算")
	_check(not game.end_turn(), "未结算不能换人")
	var before: Dictionary = game.get_snapshot()
	_check(not game.move_current_player_to(&""), "拒绝空格子 ID")
	_check(not game.move_current_player_to(Rules.SPAWN_TILE_ID), "原地不算移动")
	_check(game.get_snapshot() == before, "非法移动不改状态")
	_check(game.move_current_player_to(Rules.STOP_TILE_ID), "移动至停留点")
	_check(not game.exchange_star(0), "路过时不能兑换")
	_check(game.settle_landing(), "停留结算开放兑换")
	var visit: int = game.get_snapshot().stop_visit_id
	before = game.get_snapshot()
	_check(not game.settle_landing(), "拒绝重复落点结算")
	_check(not game.exchange_star(visit), "余额零不能兑换")
	_check(game.get_snapshot() == before, "失败兑换不改钱或星或流程")
	_check(game.change_money(0, Rules.STAR_COST - 1), "发放不足费用的金额")
	before = game.get_snapshot()
	_check(not game.exchange_star(visit), "差一金币也不能兑换")
	_check(game.get_snapshot() == before, "不足费用不能扣钱")
	_check(game.change_money(0, 1), "补齐费用")
	_check(game.exchange_star(visit), "余额恰好足够时兑换成功")
	var after: Dictionary = game.get_snapshot()
	_check(after.players[0].money == 0 and after.players[0].stars == 1, "恰好扣除费用并增加一星")
	_check(after.players[1].money == 0 and after.players[1].stars == 0, "兑换不影响另一玩家")
	_check(not game.exchange_star(visit), "拒绝重复提交同一次兑换")
	_check(not game.settle_landing(), "兑换后不能重开本次结算")
	_check(not game.move_current_player_to(&"path"), "结算完毕不能继续移动")
	_check(game.get_snapshot() == after, "重复请求不改变状态")


func _test_skip_and_stale_exchange() -> void:
	var game = MatchState.new()
	_check(game.start_game(2), "跳过兑换验证开局")
	_check(game.change_money(0, Rules.STAR_COST + 7), "预备足够费用")
	_land(game, Rules.STOP_TILE_ID)
	var old_visit: int = game.get_snapshot().stop_visit_id
	_check(game.end_turn(), "可选择不兑换而结束回合")
	_check(game.get_snapshot().players[0].money == Rules.STAR_COST + 7, "跳过不扣钱")
	_check(not game.exchange_star(old_visit), "换人后拒绝旧兑换请求")
	_land(game, &"path")
	_check(game.end_turn(), "第二名玩家结束回合")
	_check(not game.settle_landing(), "留在停留点不能凭空再次结算")
	_check(not game.move_current_player_to(Rules.STOP_TILE_ID), "必须先离开停留点")
	_check(game.move_current_player_to(&"path"), "离开停留点")
	_check(game.move_current_player_to(Rules.STOP_TILE_ID), "再次返回停留点")
	_check(game.settle_landing(), "新停留结算")
	var before: Dictionary = game.get_snapshot()
	_check(before.stop_visit_id != old_visit, "每次停留有新编号")
	_check(not game.exchange_star(old_visit), "旧兑换请求不能用于新停留")
	_check(game.get_snapshot() == before, "过期请求无副作用")
	_check(game.exchange_star(before.stop_visit_id), "新编号可兑换")
	_check(game.get_snapshot().players[0].money == 7, "余额有余时只扣固定费用")


func _test_return_and_finish() -> void:
	var game = MatchState.new()
	_check(game.start_game(2), "胜负验证开局")
	# 玩家 1（索引 1）获胜，避免默认赢家恰好为 0 掩盖错误。
	_check(game.change_money(1, Rules.STAR_COST * (Rules.TARGET_STARS + 1)), "准备购星资金")
	_land(game, &"path")
	_check(game.end_turn(), "轮到玩家 1")
	for purchase in range(Rules.TARGET_STARS):
		if purchase > 0:
			_check(game.move_current_player_to(&"path"), "下一次购星前离开停留点")
		_land(game, Rules.STOP_TILE_ID)
		var visit: int = game.get_snapshot().stop_visit_id
		_check(game.exchange_star(visit), "购买第 %d 星" % (purchase + 1))
		var state: Dictionary = game.get_snapshot()
		_check(state.players[1].stars == purchase + 1, "购星只增加一星")
		_check(not state.is_finished and state.winner_index == -1, "本次购星达到目标不立即获胜")
		_check(not game.exchange_star(visit), "有余额也不能同次买第二星")
		_check(game.end_turn(), "购星后结束回合")
		_check(game.move_current_player_to(&"detour"), "另一玩家移动")
		_check(game.move_current_player_to(&"path"), "另一玩家落到普通格")
		_check(game.settle_landing(), "另一玩家结算")
		_check(game.end_turn(), "轮回购星玩家")
	_check(not game.settle_landing(), "刚买第三星后原地不能制造获胜")
	# 已达标时先路过中心点，走到别处落地也不能获胜。
	_check(game.move_current_player_to(&"path"), "达标后离开停留点")
	_check(game.move_current_player_to(Rules.STOP_TILE_ID), "路过停留点")
	_check(not game.get_snapshot().is_finished, "路过不触发胜利")
	_check(game.move_current_player_to(&"detour"), "继续移动离开中心点")
	_check(game.settle_landing(), "在普通格落地")
	_check(not game.get_snapshot().is_finished, "非停留点落地不胜利")
	_check(game.end_turn(), "普通落点结束回合")
	_land(game, &"detour")
	_check(game.end_turn(), "再次轮到达标玩家")
	_check(game.move_current_player_to(Rules.STOP_TILE_ID), "达标后再次落在停留点")
	var money_before_win: int = game.get_snapshot().players[1].money
	_check(game.settle_landing(), "胜利结算成功")
	var finished: Dictionary = game.get_snapshot()
	_check(finished.is_finished and finished.winner_index == 1, "已有目标星数的当前玩家获胜")
	_check(finished.current_player_index == 1, "胜利后保留当前玩家")
	_check(finished.players[1].money == money_before_win, "胜利结算不再扣兑换费")
	for index in range(2):
		_check(not game.change_money(index, 10), "结束后拒绝加钱")
		_check(not game.change_money(index, -1), "结束后拒绝扣钱")
	_check(not game.move_current_player_to(&"path"), "结束后拒绝移动")
	_check(not game.settle_landing(), "结束后拒绝结算")
	_check(not game.exchange_star(finished.stop_visit_id), "结束后拒绝兑换")
	_check(not game.end_turn(), "结束后拒绝切换玩家")
	_check(not game.start_game(4), "结束后拒绝覆盖原对局")
	_check(game.get_snapshot() == finished, "结束后全部对局状态保持不变")
