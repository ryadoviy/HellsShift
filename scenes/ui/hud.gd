
extends CanvasLayer

@onready var recipe_label: Label = $Interface/RecipePanel/RecipeLabel
@onready var time_label: Label = $Interface/TimeLabel
@onready var score_label: Label = $Interface/ScoreLabel
@onready var fire_label: Label = $Interface/FireLabel
@onready var fire_bar: ProgressBar = $Interface/FireBar
@onready var inventory_label: Label = $Interface/InventoryLabel
@onready var hint_label: Label = $Interface/HintLabel


func _ready() -> void:
	update_display({
		"score": 300,
		"time": 165.0,
		"fire": 40.0,
		"recipe": "Invisibility",
		"ingredients": ["mushroom", "eye", "web"],
		"progress": 1,
		"item": "mushroom"
	})


func update_display(data: Dictionary) -> void:
	var score: int = int(data.get("score", 0))
	var time_left: float = maxf(
		0.0, float(data.get("time", 180.0))
	)
	var fire: float = float(data.get("fire", 20.0))

	score_label.text = "SCORE: %d" % score

	var total_seconds: int = int(ceil(time_left))
	var minutes: int = floori(float(total_seconds) / 60.0)
	var seconds: int = total_seconds % 60

	time_label.text = "%02d:%02d" % [
		minutes, seconds
	]

	fire_bar.value = fire
	fire_label.text = "FIRE: %d%%" % int(fire)

	if fire >= 80.0:
		fire_label.add_theme_color_override(
			"font_color", Color("#FF5555")
		)
	else:
		fire_label.add_theme_color_override(
			"font_color", Color("#F0C98A")
		)

	var recipe_name: String = str(
		data.get("recipe", "Unknown")
	)

	var ingredients: Array = data.get(
		"ingredients", []
	)

	var progress: int = int(
		data.get("progress", 0)
	)

	var recipe_text: String = (
		"RECIPE: " + recipe_name + "\n"
	)

	for i in range(ingredients.size()):
		if i < progress:
			recipe_text += "✓ "
		else:
			recipe_text += "• "

		recipe_text += str(ingredients[i]) + " "

	recipe_label.text = recipe_text

	var item: String = str(data.get("item", ""))

	if item.is_empty():
		inventory_label.text = "INVENTORY: EMPTY"
	else:
		inventory_label.text = "INVENTORY: " + item


func set_hint(message: String) -> void:
	hint_label.text = message
