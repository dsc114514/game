extends RefCounted
## Controller 内部的一局数据事务；不依赖场景、显示或路线数据。
## phase 限制合法数据操作及结算次数；本层没有时钟或输入，不自行推进回合。
## 何时移动、结算、兑换或结束回合只由 TurnController 决定。

const Rules = preload("res://example/gameplay/mvp_rules.gd")

enum Phase { NOT_STARTED, WAITING_FOR_MOVE, MOVING, AT_STOP, TURN_COMPLETE, FINISHED }

var _players: Array[Dictionary] = []
var _current_player_index: int = -1
var _winner_index: int = -1
var _phase: Phase = Phase.NOT_STARTED
var _stop_visit_id: int = 0


func get_snapshot() -> Dictionary:
	# 深拷贝避免显示或测试代码经由返回值改写真实状态。
	return {
		"players": _players.duplicate(true),
		"current_player_index": _current_player_index,
		"is_finished": _phase == Phase.FINISHED,
		"winner_index": _winner_index,
		"phase": _phase,
		"stop_visit_id": _stop_visit_id if _phase == Phase.AT_STOP else -1,
	}


func start_game(player_count: int) -> bool:
	if _phase != Phase.NOT_STARTED:
		return false
	if player_count < Rules.MIN_PLAYERS or player_count > Rules.MAX_PLAYERS:
		return false
	for index in range(player_count):
		_players.append({
			"position": Rules.SPAWN_TILE_ID,
			"money": Rules.INITIAL_MONEY,
			"stars": Rules.INITIAL_STARS,
		})
	_current_player_index = 0
	_phase = Phase.WAITING_FOR_MOVE
	return true


func change_money(player_index: int, amount: int) -> bool:
	if _phase == Phase.NOT_STARTED or _phase == Phase.FINISHED:
		return false
	if player_index < 0 or player_index >= _players.size():
		return false
	var balance: int = _players[player_index]["money"]
	# 拒绝透支和 int64 溢出，失败时保持整局不变。
	if amount < 0 and amount < -balance:
		return false
	if amount > 0 and balance > 9223372036854775807 - amount:
		return false
	_players[player_index]["money"] = balance + amount
	return true


func move_current_player_to(tile_id: StringName) -> bool:
	# 后续路线层逐格调用此方法；路过任何格子都不触发结算。
	if _phase != Phase.WAITING_FOR_MOVE and _phase != Phase.MOVING:
		return false
	if tile_id.is_empty() or tile_id == _players[_current_player_index]["position"]:
		return false
	_players[_current_player_index]["position"] = tile_id
	_phase = Phase.MOVING
	return true


func settle_landing() -> bool:
	# 只在走完步数后调用；一次移动只允许结算一次。
	if _phase != Phase.MOVING:
		return false
	var player: Dictionary = _players[_current_player_index]
	if player["position"] != Rules.STOP_TILE_ID:
		_phase = Phase.TURN_COMPLETE
		return true
	# 先判断进入本次结算前的星数，再开放兑换。
	if player["stars"] >= Rules.TARGET_STARS:
		_winner_index = _current_player_index
		_phase = Phase.FINISHED
		return true
	_stop_visit_id += 1
	_phase = Phase.AT_STOP
	return true


func exchange_star(visit_id: int) -> bool:
	# 编号来自本次 AT_STOP 快照；旧请求不能用于后一次停留。
	if _phase != Phase.AT_STOP or visit_id != _stop_visit_id:
		return false
	var player: Dictionary = _players[_current_player_index]
	if player["money"] < Rules.STAR_COST:
		return false
	player["money"] -= Rules.STAR_COST
	player["stars"] += 1
	# 本次刚达到目标也只结束结算，必须离开后再次落在停留点。
	_phase = Phase.TURN_COMPLETE
	return true


func end_turn() -> bool:
	# 在停留点直接结束回合，表示选择不兑换。
	if _phase != Phase.AT_STOP and _phase != Phase.TURN_COMPLETE:
		return false
	_current_player_index = (_current_player_index + 1) % _players.size()
	_phase = Phase.WAITING_FOR_MOVE
	return true
