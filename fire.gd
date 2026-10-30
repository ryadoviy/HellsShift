extends Node2D
class_name FireSystem

signal fire_changed(value: float)
signal fire_maxed

@export var level: float = 20.0
@onready var flame: Polygon2D = $Flame
@onready var light: PointLight2D = $PointLight2D

var _has_emitted_max := false

func _ready() -> void:
	set_level(level)

func increase(amount: float) -> void:
	set_level(level + amount)

func decrease(amount: float) -> void:
	set_level(level - amount)

func set_level(value: float) -> void:
	level = clampf(value, 0.0, 100.0)
	var scale_factor := 0.45 + level / 100.0
	flame.scale = Vector2(scale_factor, scale_factor)
	light.energy = 0.35 + level / 100.0
	fire_changed.emit(level)
	if level >= 100.0 and not _has_emitted_max:
		_has_emitted_max = true
		fire_maxed.emit()
	elif level < 100.0:
		_has_emitted_max = false
