extends Node
class_name RecipeManager

signal recipe_changed
signal ingredient_correct
signal ingredient_wrong
signal brewing_started
signal recipe_completed

const RECIPES = [
	{
		"name": "Invisibility",
		"ingredients": [&"mushroom", &"eye", &"web"]
	},
	{
		"name": "Speed",
		"ingredients": [&"bat", &"mushroom", &"bone"]
	},
	{
		"name": "Immortality",
		"ingredients": [&"skull", &"eye", &"bat"]
	},
	{
		"name": "Poison",
		"ingredients": [&"spider", &"mushroom", &"bone"]
	}
]

@export var brewing_duration: float = 1.5

var current_recipe: Dictionary = {}
var ingredient_index: int = 0
var completed_count: int = 0
var is_brewing: bool = false
var brewing_time_left: float = 0.0


func reset() -> void:
	completed_count = 0
	is_brewing = false
	brewing_time_left = 0.0
	choose_recipe()


func choose_recipe() -> void:
	var previous_name: String = str(
		current_recipe.get("name", "")
	)
	var choices: Array[int] = []

	for index in range(RECIPES.size()):
		if RECIPES[index]["name"] != previous_name:
			choices.append(index)

	var chosen_index: int = choices.pick_random()
	current_recipe = RECIPES[chosen_index].duplicate(true)
	ingredient_index = 0
	recipe_changed.emit()


func add_ingredient(item_id: StringName) -> bool:
	if is_brewing or current_recipe.is_empty() or item_id == &"":
		return false

	var ingredients: Array = current_recipe["ingredients"]

	if ingredient_index >= ingredients.size():
		return false

	var expected_item: StringName = ingredients[ingredient_index]

	if item_id != expected_item:
		ingredient_wrong.emit()
		return false

	ingredient_index += 1

	if ingredient_index == ingredients.size():
		is_brewing = true
		brewing_time_left = brewing_duration

	ingredient_correct.emit()
	recipe_changed.emit()

	if is_brewing:
		brewing_started.emit()

	return true


# Gameplay викликає це лише під час активної гри.
func advance_brewing(delta: float) -> void:
	if not is_brewing:
		return

	brewing_time_left = maxf(0.0, brewing_time_left - delta)

	if brewing_time_left > 0.0:
		return

	is_brewing = false
	completed_count += 1
	choose_recipe()
	recipe_completed.emit()