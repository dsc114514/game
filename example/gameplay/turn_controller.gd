extends RefCounted
## 回合规则：单次掷骰、逐连接移动、等待选择、唯一落点结算与自动轮换。
## 显示只提交操作和读取快照，不直接修改 MatchState。

const MatchState = preload("res://example/gameplay/match_state.gd")
const RouteData = preload("res://example/gameplay/route_data.gd")
const Rules = preload("res://example/gameplay/mvp_rules.gd")

enum Phase { NOT_STARTED, WAITING_FOR_ROLL, MOVING, WAITING_FOR_PATH, WAITING_FOR_EXCHANGE, FINISHED }

var _match = MatchState.new()
var _by_id: Dictionary = {}
var _errors := PackedStringArray()
var _rng := RandomNumberGenerator.new()
var _test_controls: bool = false
var _phase: Phase = Phase.NOT_STARTED
var _input_id: int = 0
var _turn_number: int = 0
var _remaining_steps: int = 0
var _last_roll: int = 0
var _logs := PackedStringArray()


func _init(test_controls: bool = false, test_tiles: Array = []) -> void:
	_test_controls = test_controls
	var tiles: Array = test_tiles.duplicate(true) if test_controls and not test_tiles.is_empty() else RouteData.get_tiles()
	_errors = RouteData.validate(tiles)
	if _errors.is_empty():
		for tile in tiles:
			_by_id[StringName(tile.id)] = tile
	_rng.randomize()


func get_snapshot() -> Dictionary:
	var state: Dictionary = _match.get_snapshot()
	state["turn_phase"] = _phase
	state["input_id"] = _input_id
	state["turn_number"] = _turn_number
	state["remaining_steps"] = _remaining_steps
	state["last_roll"] = _last_roll
	state["legal_exits"] = _current_tile().next.duplicate() if _phase == Phase.WAITING_FOR_PATH else []
	state["logs"] = _logs.duplicate()
	state["errors"] = _errors.duplicate()
	state["test_controls"] = _test_controls
	return state


func start_game(player_count: int) -> bool:
	if _phase != Phase.NOT_STARTED or not _errors.is_empty() or not _match.start_game(player_count):
		return false
	_turn_number = 1
	_log("START %d PLAYERS" % player_count)
	_wait(Phase.WAITING_FOR_ROLL)
	return true


func roll_dice(input_id: int) -> bool:
	if not _accepts(Phase.WAITING_FOR_ROLL, input_id):
		return false
	return _begin_roll(_rng.randi_range(Rules.DICE_MIN, Rules.DICE_MAX))


func roll_for_test(value: int, input_id: int) -> bool:
	if not _test_controls or not _accepts(Phase.WAITING_FOR_ROLL, input_id):
		return false
	if value < Rules.DICE_MIN or value > Rules.DICE_MAX:
		return false
	return _begin_roll(value)


func advance() -> bool:
	# 每次只走一条连接；UI 可定时调用，命令行验证无需等待动画。
	if _phase != Phase.MOVING or _remaining_steps <= 0:
		return false
	return _move_one(StringName(_current_tile().next[0]))


func choose_path(target: StringName, input_id: int) -> bool:
	if not _accepts(Phase.WAITING_FOR_PATH, input_id) or not _current_tile().next.has(target):
		return false
	_log("P%d CHOSE %s TO %s" % [_match.get_snapshot().current_player_index + 1, String(_current_tile().id).to_upper(), String(target).to_upper()])
	return _move_one(target)


func exchange_star(input_id: int) -> bool:
	if not _accepts(Phase.WAITING_FOR_EXCHANGE, input_id):
		return false
	var state: Dictionary = _match.get_snapshot()
	if not _match.exchange_star(state.stop_visit_id):
		return false
	var player: Dictionary = _match.get_snapshot().players[state.current_player_index]
	_log("P%d EXCHANGED %d MONEY FOR 1 STAR / MONEY %d / STARS %d" % [state.current_player_index + 1, Rules.STAR_COST, player.money, player.stars])
	_finish_turn()
	return true


func skip_exchange(input_id: int) -> bool:
	if not _accepts(Phase.WAITING_FOR_EXCHANGE, input_id):
		return false
	_log("P%d SKIPPED EXCHANGE" % (_match.get_snapshot().current_player_index + 1))
	_finish_turn()
	return true


func _accepts(phase: Phase, input_id: int) -> bool:
	return _phase == phase and _input_id == input_id


func _wait(phase: Phase) -> void:
	_phase = phase
	# 同一回合可连续遇到岔路；每次等待均换编号，旧选择不能复用于新岔路。
	_input_id += 1


func _current_tile() -> Dictionary:
	var state: Dictionary = _match.get_snapshot()
	return _by_id[state.players[state.current_player_index].position]


func _begin_roll(value: int) -> bool:
	_last_roll = value
	_remaining_steps = value
	_phase = Phase.MOVING
	_log("P%d ROLL %d" % [_match.get_snapshot().current_player_index + 1, value])
	_continue_or_settle()
	return true


func _move_one(target: StringName) -> bool:
	if not _match.move_current_player_to(target):
		return false
	_phase = Phase.MOVING
	_remaining_steps -= 1
	_log("P%d TO %s / LEFT %d" % [_match.get_snapshot().current_player_index + 1, String(target).to_upper(), _remaining_steps])
	_continue_or_settle()
	return true


func _continue_or_settle() -> void:
	# 必须先检查步数：恰好落在岔路时不要求选择未使用的出口。
	if _remaining_steps == 0:
		_settle_landing()
	elif _current_tile().next.size() > 1:
		_wait(Phase.WAITING_FOR_PATH)
	else:
		_phase = Phase.MOVING


func _settle_landing() -> void:
	# MatchState 也只接受一次结算，拒绝后绝不发奖或轮换。
	if _phase != Phase.MOVING or _remaining_steps != 0 or not _match.settle_landing():
		return
	var state: Dictionary = _match.get_snapshot()
	var player_number: int = state.current_player_index + 1
	var tile := _current_tile()
	_log("P%d LANDED %s / %s" % [player_number, String(tile.id).to_upper(), String(tile.type).to_upper()])
	if state.is_finished:
		_phase = Phase.FINISHED
		_log("P%d WINS WITH %d STARS" % [player_number, state.players[state.current_player_index].stars])
		return
	match tile.type:
		"stop":
			_log("P%d AT CENTER / EXCHANGE OR SKIP" % player_number)
			_wait(Phase.WAITING_FOR_EXCHANGE)
			return
		"coin":
			if _match.change_money(state.current_player_index, Rules.COIN_REWARD):
				_log("P%d COIN %s / GAIN %d MONEY / MONEY %d" % [player_number, String(tile.id).to_upper(), Rules.COIN_REWARD, _match.get_snapshot().players[state.current_player_index].money])
		"shop", "event":
			_log("P%d %s %s / LOG ONLY" % [player_number, String(tile.type).to_upper(), String(tile.id).to_upper()])
		_:
			_log("P%d LANDED %s / NO REWARD" % [player_number, String(tile.id).to_upper()])
	_finish_turn()


func _finish_turn() -> void:
	if not _match.end_turn():
		return
	_turn_number += 1
	_wait(Phase.WAITING_FOR_ROLL)
	_log("TURN %d / P%d TO ROLL" % [_turn_number, _match.get_snapshot().current_player_index + 1])


func _log(message: String) -> void:
	_logs.append(message)
	if _logs.size() > 128:
		_logs.remove_at(0)
