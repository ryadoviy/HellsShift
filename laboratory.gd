extends Node2D
class_name Laboratory

signal location_changed(location_id: String)

@export var location_id := "laboratory"

func _ready() -> void:
	location_changed.emit(location_id)
