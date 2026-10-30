extends Node
class_name Gameplay

const ITEM_NAMES = {
	&"mushroom": "Mushroom",
	&"eye": "Eye",
	&"web": "Web",
	&"bat": "Bat",
	&"bone": "Bone",
	&"skull": "Skull",
	&"spider": "Spider",
	&"water": "Water"
}

var manager: Node
var player: CorePlayer
var recipes: RecipeManager
var objects: Node2D
var recipe_label: Label
var inventory_label: Label


func setup(game_manager: Node) -> void:
	manager = game_manager
	player = manager.get_node("Player") as CorePlayer

	recipes = RecipeManager.new()
	add_child(recipes)

	objects = Node2D.new()
	objects.name = "GameplayObjects"
	manager.add_child(objects)

	recipe_label = create_label(Vector2(75, 175), Vector2(1130, 65))
	inventory_label = create_label(Vector2(75, 570), Vector2(1130, 35))

	recipes.recipe_changed.connect(update_recipe)
	recipes.recipe_completed.connect(manager.on_recipe_completed)
	recipes.ingredient_wrong.connect(manager.on_ingredient_wrong)
	player.inventory.item_changed.connect(update_inventory)
	player.item_dropped.connect(on_item_dropped)

	var ingredient_ids: Array[StringName] = [
		&"mushroom", &"eye", &"web", &"bat",
		&"bone", &"skull", &"spider"
	]

	for index in range(ingredient_ids.size()):
		var item_id: StringName = ingredient_ids[index]
		create_object(
			GameInteractable.Kind.INGREDIENT,
			item_id,
			Vector2(160 + index * 155, 270),
			Color(0.65, 0.3, 0.8)
		)

	create_object(
		GameInteractable.Kind.CAULDRON,
		&"",
		Vector2(640, 420),
		Color(0.2, 0.7, 0.4)
	)

	create_object(
		GameInteractable.Kind.WATER,
		&"water",
		Vector2(1100, 420),
		Color(0.2, 0.6, 1.0)
	)


func create_label(label_position: Vector2, label_size: Vector2) -> Label:
	var label := Label.new()
	label.position = label_position
	label.size = label_size
	label.add_theme_font_size_override("font_size", 20)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	manager.get_node("HUD").add_child(label)
	return label


func create_object(
	kind: GameInteractable.Kind,
	item_id: StringName,
	object_position: Vector2,
	color: Color,
	dropped: bool = false
) -> GameInteractable:
	var target := GameInteractable.new()
	target.kind = kind
	target.item_id = item_id
	target.position = object_position
	target.object_color = color
	target.set_meta("dropped", dropped)

	if kind == GameInteractable.Kind.CAULDRON:
		target.display_name = "Cauldron"
	else:
		target.display_name = str(ITEM_NAMES.get(item_id, item_id))

	target.interacted.connect(on_interacted)
	objects.add_child(target)
	return target


func on_interacted(target: GameInteractable, actor: Node) -> void:
	if manager.state != GameManager.GameState.PLAYING:
		return

	if actor != player:
		return

	if target.kind == GameInteractable.Kind.CAULDRON:
		if not player.inventory.has_item():
			return

		var item_id := player.inventory.remove_item()

		if item_id == &"water":
			manager.use_water()
		else:
			recipes.add_ingredient(item_id)

	else:
		var taken := player.inventory.take_item(target.item_id)

		if taken and target.get_meta("dropped", false):
			target.hide()
			target.queue_free()


func on_item_dropped(item_id: StringName, drop_position: Vector2) -> void:
	# Залишаємо предмет усередині стін кімнати.
	var safe_position := Vector2(
		clampf(drop_position.x, 85.0, 1195.0),
		clampf(drop_position.y, 200.0, 590.0)
	)

	create_object(
		GameInteractable.Kind.INGREDIENT,
		item_id,
		safe_position,
		Color(0.9, 0.65, 0.25),
		true
	)


func reset_round() -> void:
	for target in objects.get_children():
		if target.get_meta("dropped", false):
			target.hide()
			target.queue_free()

	player.reset_player()
	recipes.reset()


func update_recipe() -> void:
	if recipes.current_recipe.is_empty():
		recipe_label.text = ""
		return

	var ingredients: Array = recipes.current_recipe["ingredients"]
	var steps := PackedStringArray()

	for index in range(ingredients.size()):
		var item_name: String = str(ITEM_NAMES[ingredients[index]])

		if index < recipes.ingredient_index:
			item_name = "[OK] " + item_name

		steps.append(item_name)

	recipe_label.text = "POTION: %s\n%s" % [
		recipes.current_recipe["name"],
		" > ".join(steps)
	]


func update_inventory(item_id: StringName) -> void:
	var item_name: String = str(ITEM_NAMES.get(item_id, "Empty"))
	inventory_label.text = "HOLDING: %s    |    Q - drop" % item_name


func _process(_delta: float) -> void:
	if recipe_label == null:
		return

	var playing: bool = manager.state == GameManager.GameState.PLAYING
	recipe_label.visible = playing
	inventory_label.visible = playing