extends Control
## 仅用于观看的预览：把 CardFace 实例放大 4 倍并居中。
## 缩放只作用于这份实例，不写进 card_face.tscn。

const PREVIEW_SCALE := Vector2(4, 4)

@onready var _card: Control = $CardFace


func _ready() -> void:
	_card.scale = PREVIEW_SCALE
	_center_card()
	get_viewport().size_changed.connect(_center_card)


func _center_card() -> void:
	var view_size := get_viewport_rect().size
	var card_size := _card.size * PREVIEW_SCALE
	# 取整，避免半像素位置。
	_card.position = ((view_size - card_size) / 2.0).floor()
