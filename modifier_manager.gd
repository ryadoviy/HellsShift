extends Node
class_name ModifierManager

var enabled := false

func on_game_started(_game: Node) -> void:
	pass

func on_ingredient_added(_game: Node, _item_id: String) -> void:
	pass

func on_potion_completed(_game: Node) -> void:
	pass

func on_location_changed(_game: Node, _location_id: String) -> void:
	pass

func update_modifier(_game: Node, _delta: float) -> void:
	pass
