extends Node2D
## 本机轮流操作的最小界面；所有游戏操作均交给 TurnController。

const TurnController = preload("res://example/gameplay/turn_controller.gd")
const Board = preload("res://example/board/route_preview.gd")
const Layout = preload("res://example/board/route_layout.gd")
const Rules = preload("res://example/gameplay/mvp_rules.gd")
const FONT = preload("res://example/board/placeholder_font.fnt")
const PLAYER_COLORS: Array[Color] = [Color("e58080"), Color("80b3e5"), Color("e5ce80"), Color("80c7a0")]
const STEP_SECONDS: float = 0.18

@export var test_controls_enabled: bool = false

var _game
var _ui := Control.new()
var _tokens := Node2D.new()
var _status: Label
var _next_action: Label
var _players: Array[Label] = []
var _start_buttons: Array[Button] = []
var _roll: Button
var _exchange: Button
var _skip: Button
var _restart: Button
var _choices := HBoxContainer.new()
var _test_buttons: Array[Button] = []
var _log: Label
var _session: int = 0
var _elapsed: float = 0.0


func _ready() -> void:
	test_controls_enabled = test_controls_enabled or OS.get_cmdline_user_args().has("--test-dice")
	_game = TurnController.new(test_controls_enabled)
	add_child(_tokens)
	_tokens.draw.connect(_draw_players)
	_ui.name = "UI"
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme := Theme.new()
	theme.default_font = FONT
	theme.default_font_size = 16
	for style in ["normal", "hover", "pressed", "disabled", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Board.FILL
		box.border_color = Board.INK if style in ["hover", "pressed", "focus"] else Board.LINE
		box.set_border_width_all(1)
		box.anti_aliasing = false
		theme.set_stylebox(style, "Button", box)
	_ui.theme = theme
	add_child(_ui)
	_label("Title", "MVP LOCAL HOTSEAT", Vector2i(64, 16), Vector2i(448, 32))
	_status = _label("Status", "", Vector2i(544, 16), Vector2i(544, 48))
	for count in range(Rules.MIN_PLAYERS, Rules.MAX_PLAYERS + 1):
		var button := _button("Start%d" % count, "START %d" % count, Vector2i(64 + (count - 2) * 144, 48), Vector2i(128, 32))
		_start_buttons.append(button)
	for index in range(Rules.MAX_PLAYERS):
		_players.append(_label("Player%d" % (index + 1), "", Vector2i(64 + index * 256, 96), Vector2i(240, 48)))
		_players[index].modulate = PLAYER_COLORS[index]
	_next_action = _label("NextAction", "", Vector2i(64, 608), Vector2i(1024, 32))
	_roll = _button("Roll", "ROLL", Vector2i(64, 640), Vector2i(128, 32))
	_choices.name = "Choices"
	_choices.position = Vector2(208, 640)
	_choices.add_theme_constant_override("separation", 16)
	_ui.add_child(_choices)
	_exchange = _button("Exchange", "EXCHANGE %d" % Rules.STAR_COST, Vector2i(528, 640), Vector2i(208, 32))
	_skip = _button("Skip", "SKIP", Vector2i(752, 640), Vector2i(128, 32))
	_restart = _button("Restart", "NEW GAME", Vector2i(896, 640), Vector2i(192, 32))
	_label("Rules", "CENTER: %d MONEY FOR 1 STAR / ONCE PER VISIT / OPTIONAL\nGOAL: %d STARS. LEAVE CENTER, THEN LAND ON CENTER AGAIN TO WIN.\nBUYING THE LAST STAR OR PASSING CENTER DOES NOT WIN.\nFINAL TILE ONLY / COIN: %d MONEY / SHOP AND EVENT: LOG ONLY" % [Rules.STAR_COST, Rules.TARGET_STARS, Rules.COIN_REWARD], Vector2i(64, 688), Vector2i(1024, 64))
	if test_controls_enabled:
		_label("TestLabel", "TEST DICE", Vector2i(544, 64), Vector2i(128, 32))
		for value in range(Rules.DICE_MIN, Rules.DICE_MAX + 1):
			var button := _button("Test%d" % value, str(value), Vector2i(688 + (value - 1) * 64, 64), Vector2i(48, 32))
			_test_buttons.append(button)
	_log = _label("Log", "", Vector2i(64, 768), Vector2i(1024, 112))
	_refresh()


func _process(delta: float) -> void:
	if _game == null or _game.get_snapshot().turn_phase != TurnController.Phase.MOVING:
		_elapsed = 0.0
		return
	_elapsed += delta
	if _elapsed >= STEP_SECONDS:
		_elapsed = 0.0
		_game.advance()
		_refresh()


func _on_start(count: int, session: int) -> void:
	if session != _session:
		return
	_game.start_game(count)
	_refresh()


func _on_roll(input_id: int, session: int) -> void:
	if session != _session:
		return
	_game.roll_dice(input_id)
	_refresh()


func _on_test_roll(value: int, input_id: int, session: int) -> void:
	if session != _session:
		return
	_game.roll_for_test(value, input_id)
	_refresh()


func _on_choose(target: StringName, input_id: int, session: int) -> void:
	if session != _session:
		return
	_game.choose_path(target, input_id)
	_refresh()


func _on_exchange(input_id: int, session: int) -> void:
	if session != _session:
		return
	_game.exchange_star(input_id)
	_refresh()


func _on_skip(input_id: int, session: int) -> void:
	if session != _session:
		return
	_game.skip_exchange(input_id)
	_refresh()


func _on_restart(session: int) -> void:
	if session != _session or not _game.get_snapshot().is_finished:
		return
	_session += 1
	_game = TurnController.new(test_controls_enabled)
	_elapsed = 0.0
	_refresh()


func _bind_action(button: Button, action: Callable) -> void:
	# 绑定本次显示的局编号与等待编号；旧回调不可作用于新等待或新局。
	for connection in button.pressed.get_connections():
		button.pressed.disconnect(connection.callable)
	button.pressed.connect(action)


func _refresh() -> void:
	var state: Dictionary = _game.get_snapshot()
	var phase: int = state.turn_phase
	for index in range(_start_buttons.size()):
		var button := _start_buttons[index]
		button.disabled = phase != TurnController.Phase.NOT_STARTED or not state.errors.is_empty()
		_bind_action(button, _on_start.bind(Rules.MIN_PLAYERS + index, _session))
	_roll.disabled = phase != TurnController.Phase.WAITING_FOR_ROLL
	_bind_action(_roll, _on_roll.bind(state.input_id, _session))
	for index in range(_test_buttons.size()):
		var button := _test_buttons[index]
		button.disabled = _roll.disabled
		_bind_action(button, _on_test_roll.bind(Rules.DICE_MIN + index, state.input_id, _session))
	_exchange.disabled = phase != TurnController.Phase.WAITING_FOR_EXCHANGE
	_skip.disabled = _exchange.disabled
	if not _exchange.disabled:
		_exchange.disabled = state.players[state.current_player_index].money < Rules.STAR_COST
	_bind_action(_exchange, _on_exchange.bind(state.input_id, _session))
	_bind_action(_skip, _on_skip.bind(state.input_id, _session))
	_restart.disabled = not state.is_finished
	_bind_action(_restart, _on_restart.bind(_session))
	for child in _choices.get_children():
		_choices.remove_child(child)
		child.queue_free()
	for target in state.legal_exits:
		var button := Button.new()
		button.name = String(target)
		button.text = "TO " + String(target).to_upper()
		button.custom_minimum_size = Vector2(144, 32)
		button.pressed.connect(_on_choose.bind(StringName(target), state.input_id, _session))
		_choices.add_child(button)
	for index in range(_players.size()):
		if index < state.players.size():
			var player: Dictionary = state.players[index]
			var position_text: String = ("CURRENT AT " if index == state.current_player_index else "AT ") + String(player.position).to_upper()
			_players[index].text = "P%d MONEY %d STARS %d\n%s" % [index + 1, player.money, player.stars, position_text]
		else:
			_players[index].text = ""
	if not state.errors.is_empty():
		_status.text = "INVALID ROUTE / SEE OUTPUT"
		_next_action.text = "CANNOT START: ROUTE VALIDATION FAILED."
		for message in state.errors:
			push_error(message)
	elif phase == TurnController.Phase.NOT_STARTED:
		_status.text = "LOCAL PLAY / %d TO %d PLAYERS\nRANDOM DICE %d TO %d" % [Rules.MIN_PLAYERS, Rules.MAX_PLAYERS, Rules.DICE_MIN, Rules.DICE_MAX]
		_next_action.text = "CLICK START 2 OR START 3 OR START 4 TO BEGIN."
	elif state.is_finished:
		_status.text = "P%d WINS / GAME OVER\nDICE %d / REMAINING STEPS %d" % [state.winner_index + 1, state.last_roll, state.remaining_steps]
		_next_action.text = "PLAYER %d WINS. CLICK NEW GAME, THEN CHOOSE A PLAYER COUNT." % (state.winner_index + 1)
	else:
		var dice_text: String = "-" if phase == TurnController.Phase.WAITING_FOR_ROLL else str(state.last_roll)
		_status.text = "TURN %d / CURRENT PLAYER %d\nDICE %s / REMAINING STEPS %d" % [state.turn_number, state.current_player_index + 1, dice_text, state.remaining_steps]
		var player_number: int = state.current_player_index + 1
		match phase:
			TurnController.Phase.WAITING_FOR_ROLL:
				_next_action.text = "PLAYER %d: CLICK ROLL TO BEGIN YOUR TURN." % player_number
				if state.players[state.current_player_index].stars >= Rules.TARGET_STARS:
					_next_action.text = "PLAYER %d: CLICK ROLL. LAND ON CENTER AGAIN TO WIN." % player_number
			TurnController.Phase.MOVING:
				_next_action.text = "PLAYER %d: MOVING / PLEASE WAIT. EACH ARROW COSTS ONE STEP." % player_number
			TurnController.Phase.WAITING_FOR_PATH:
				_next_action.text = "PLAYER %d: CHOOSE AN EXIT BELOW. KEEP YOUR %d REMAINING STEPS." % [player_number, state.remaining_steps]
			TurnController.Phase.WAITING_FOR_EXCHANGE:
				if _exchange.disabled:
					_next_action.text = "PLAYER %d: NEED %d MONEY / HAVE %d. CLICK SKIP TO END TURN." % [player_number, Rules.STAR_COST, state.players[state.current_player_index].money]
				else:
					_next_action.text = "PLAYER %d: CLICK EXCHANGE %d FOR ONE STAR, OR SKIP TO END TURN." % [player_number, Rules.STAR_COST]
	var recent := PackedStringArray()
	for index in range(maxi(0, state.logs.size() - 7), state.logs.size()):
		recent.append(state.logs[index])
	_log.text = "\n".join(recent)
	_tokens.queue_redraw()


func _draw_players() -> void:
	var state: Dictionary = _game.get_snapshot()
	for index in range(state.players.size()):
		var rect := _token_rect(state.players[index].position, index)
		var point := Vector2i(rect.position)
		_tokens.draw_rect(rect, PLAYER_COLORS[index])
		_tokens.draw_rect(rect, Board.INK if index == state.current_player_index else Board.FILL, false, 1.0)
		_tokens.draw_string(FONT, Vector2(point + Vector2i(10, 24)), str(index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Board.FILL)


func _token_rect(tile_id: StringName, player_index: int) -> Rect2:
	var center: Vector2i = Board.ORIGIN + Layout.get_positions()[String(tile_id)] * Board.GRID_STEP
	return Rect2(Vector2(center + Vector2i(-64 + player_index * 32, 32)), Vector2(32, 32))


func _label(node_name: String, text: String, point: Vector2i, dimensions: Vector2i) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.position = Vector2(point)
	label.size = Vector2(dimensions)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(label)
	return label


func _button(node_name: String, text: String, point: Vector2i, dimensions: Vector2i) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.position = Vector2(point)
	button.size = Vector2(dimensions)
	_ui.add_child(button)
	return button
