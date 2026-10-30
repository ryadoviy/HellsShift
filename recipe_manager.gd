extends Node
class_name RecipeManager

signal recipe_changed
signal ingredient_correct
signal ingredient_wrong
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

var current_recipe: Dictionary = {}
var ingredient_index: int = 0
var completed_count: int = 0


# Почати новий раунд.
func reset() -> void:
	completed_count = 0
	choose_recipe()


# Вибрати рецепт, відмінний від попереднього.
func choose_recipe() -> void:
	var previous_name: String = current_recipe.get("name", "")
	var choices: Array[int] = []

	for index in range(RECIPES.size()):
		if RECIPES[index]["name"] != previous_name:
			choices.append(index)

	var chosen_index: int = choices.pick_random()
	current_recipe = RECIPES[chosen_index].duplicate(true)
	ingredient_index = 0
	recipe_changed.emit()


# Перевірити наступний інгредієнт.
func add_ingredient(item_id: StringName) -> bool:
	if current_recipe.is_empty() or item_id == &"":
		return false

	var ingredients: Array = current_recipe["ingredients"]
	var expected_item: StringName = ingredients[ingredient_index]

	if item_id != expected_item:
		ingredient_wrong.emit()
		return false

	ingredient_index += 1
	ingredient_correct.emit()

	if ingredient_index == ingredients.size():
		completed_count += 1
		choose_recipe()
		recipe_completed.emit()
	else:
		recipe_changed.emit()

	return true