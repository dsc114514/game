@tool
extends Control
## 卡牌布局样板（96×144）。
## 只把导出值写进 tscn 里已有的节点：改文字和颜色，不创建、不删除节点。
## 颜色均为临时占位，不是锁定的调色板。

@export var card_name: String = "小吃街":
	set(value):
		card_name = value
		_apply()

@export var cost: int = 200:
	set(value):
		cost = value
		_apply()

@export_multiline var effect_text: String = "停留时支付 200。":
	set(value):
		effect_text = value
		_apply()

@export var fill_color: Color = Color(0.17, 0.18, 0.22, 1.0):
	set(value):
		fill_color = value
		_apply()

@export var border_color: Color = Color(0.78, 0.78, 0.78, 1.0):
	set(value):
		border_color = value
		_apply()

@export var icon_color: Color = Color(0.42, 0.55, 0.69, 1.0):
	set(value):
		icon_color = value
		_apply()


func _ready() -> void:
	_apply()


func _apply() -> void:
	# 实例化时 setter 可能早于子节点就绪，此时跳过，等 _ready 再写入。
	if not is_inside_tree():
		return

	var cost_label := get_node_or_null(^"CostLabel") as Label
	if cost_label:
		cost_label.text = str(cost)

	var name_label := get_node_or_null(^"NameLabel") as Label
	if name_label:
		name_label.text = card_name

	var effect_label := get_node_or_null(^"EffectLabel") as Label
	if effect_label:
		effect_label.text = effect_text

	var icon_slot := get_node_or_null(^"IconSlot") as ColorRect
	if icon_slot:
		icon_slot.color = icon_color

	var frame := get_node_or_null(^"Frame") as Panel
	if frame:
		var box := frame.get_theme_stylebox(&"panel") as StyleBoxFlat
		if box:
			box.bg_color = fill_color
			box.border_color = border_color
