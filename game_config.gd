extends Resource
class_name GameConfig

@export var duration: float = 180.0
@export var initial_fire: float = 20.0
@export var wrong_fire: float = 20.0
@export var success_fire: float = 5.0
@export var water_power: float = 30.0
@export var player_speed: float = 220.0

static func normal() -> GameConfig:
	var config := GameConfig.new()
	return config
