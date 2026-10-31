extends Node
class_name Gameplay

signal water_used

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
var cauldron: GameInteractable
var ghost_system: GhostSabotage

var feedback_layer: CanvasLayer
var feedback_label: Label
var feedback_time_left: float = 0.0
var flash_time_left: float = 0.0
var flash_color := Color.WHITE
var effect_time: float = 0.0


func setup(game_manager: Node) -> void:
	manager = game_manager
	player = manager.get_node("Player") as CorePlayer

	recipes = RecipeManager.new()
	add_child(recipes)

	objects = Node2D.new()
	objects.name = "GameplayObjects"
	manager.add_child(objects)

	_setup_feedback()

	recipes.ingredient_correct.connect(_on_ingredient_correct)
	recipes.ingredient_wrong.connect(_on_ingredient_wrong)
	recipes.brewing_started.connect(_on_brewing_started)
	recipes.recipe_completed.connect(_on_recipe_completed)
	player.item_dropped.connect(on_item_dropped)

	var ingredient_ids: Array[StringName] = [
		&"mushroom", &"eye", &"web", &"bat",
		&"bone", &"skull", &"spider"
	]

	for index in range(ingredient_ids.size()):
		create_object(
			GameInteractable.Kind.INGREDIENT,
			ingredient_ids[index],
			Vector2(400 + index * 90, 170),
			Color(0.65, 0.3, 0.8)
		)

	cauldron = create_object(
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

	ghost_system = GhostSabotage.new()
	ghost_system.name = "GhostSystem"
	add_child(ghost_system)
	ghost_system.setup(objects)


func _setup_feedback() -> void:
	feedback_layer = CanvasLayer.new()
	feedback_layer.name = "GameplayFeedback"
	feedback_layer.layer = 5
	add_child(feedback_layer)

	feedback_label = Label.new()
	feedback_label.position = Vector2(240, 240)
	feedback_label.size = Vector2(800, 50)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback_label.add_theme_font_size_override("font_size", 28)
	feedback_label.add_theme_color_override(
		"font_shadow_color", Color.BLACK
	)
	feedback_label.add_theme_constant_override("shadow_offset_x", 2)
	feedback_label.add_theme_constant_override("shadow_offset_y", 2)
	feedback_layer.add_child(feedback_label)


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

	match kind:
		GameInteractable.Kind.CAULDRON:
			target.display_name = "Cauldron"
			target.interaction_distance = 150.0
		GameInteractable.Kind.WATER:
			target.display_name = str(ITEM_NAMES.get(item_id, item_id))
			target.interaction_distance = 120.0
		_:
			target.display_name = str(ITEM_NAMES.get(item_id, item_id))
			target.interaction_distance = 70.0 if dropped else 150.0

	target.interacted.connect(on_interacted)
	objects.add_child(target)
	return target


func on_interacted(target: GameInteractable, actor: Node) -> void:
	if manager.state != GameManager.GameState.PLAYING:
		return

	if actor != player:
		return

	if target.get_meta("ghost_blocked", false):
		_show_feedback(
			"GHOST IS BLOCKING THIS INGREDIENT!",
			Color(0.8, 0.65, 1.0)
		)
		return

	if target.kind == GameInteractable.Kind.CAULDRON:
		if not player.inventory.has_item():
			if not recipes.is_brewing:
				_show_feedback("TAKE AN INGREDIENT FIRST", Color.WHITE)
			return

		var held_item: StringName = player.inventory.held_item

		if recipes.is_brewing and held_item != &"water":
			_show_feedback(
				"CAULDRON IS MIXING...",
				Color(1.0, 0.85, 0.4)
			)
			return

		var item_id: StringName = player.inventory.remove_item()

		if item_id == &"water":
			manager.use_water()
			water_used.emit()
			_flash_cauldron(Color(0.5, 0.8, 1.0))
			_show_feedback("WATER USED", Color(0.5, 0.85, 1.0))
		else:
			recipes.add_ingredient(item_id)

	else:
		var taken: bool = player.inventory.take_item(target.item_id)

		if taken:
			if target.get_meta("dropped", false):
				target.hide()
				target.queue_free()
		else:
			_show_feedback("HANDS ARE FULL — Q TO DROP", Color.WHITE)


func on_item_dropped(item_id: StringName, drop_position: Vector2) -> void:
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
	ghost_system.reset()

	for target in objects.get_children():
		if target.get_meta("dropped", false):
			target.hide()
			target.queue_free()

	player.reset_player()
	recipes.reset()

	feedback_time_left = 0.0
	flash_time_left = 0.0
	effect_time = 0.0
	feedback_label.text = ""
	cauldron.modulate = Color.WHITE


func _on_ingredient_correct() -> void:
	_flash_cauldron(Color(0.6, 1.0, 0.6))

	if not recipes.is_brewing:
		_show_feedback("CORRECT INGREDIENT!", Color(0.6, 1.0, 0.6))


func _on_ingredient_wrong() -> void:
	manager.on_ingredient_wrong()
	_flash_cauldron(Color(1.0, 0.35, 0.35))
	_show_feedback("WRONG INGREDIENT!", Color(1.0, 0.4, 0.4))


func _on_brewing_started() -> void:
	_show_feedback("MIXING...", Color(0.85, 0.65, 1.0))


func _on_recipe_completed() -> void:
	manager.on_recipe_completed()
	_flash_cauldron(Color(0.7, 1.0, 0.5))
	_show_feedback("POTION COMPLETE!", Color(0.7, 1.0, 0.5))


func _show_feedback(message: String, color: Color) -> void:
	feedback_label.text = message
	feedback_label.modulate = color
	feedback_time_left = 1.4


func _flash_cauldron(color: Color) -> void:
	flash_color = color
	flash_time_left = 0.4


func _process(delta: float) -> void:
	if manager == null or feedback_layer == null:
		return

	var playing: bool = (
		manager.state == GameManager.GameState.PLAYING
	)
	feedback_layer.visible = playing

	if ghost_system != null:
		ghost_system.visible = (
			playing
			or manager.state == GameManager.GameState.PAUSED
		)

		# Після виходу з раунду прибираємо блокування.
		if (
			not playing
			and manager.state != GameManager.GameState.PAUSED
		):
			if not ghost_system.ghosts.is_empty():
				ghost_system.reset()

	if not playing:
		return

	recipes.advance_brewing(delta)

	if manager.state != GameManager.GameState.PLAYING:
		feedback_layer.hide()
		return

	ghost_system.advance(delta)

	effect_time += delta
	feedback_time_left = maxf(0.0, feedback_time_left - delta)
	flash_time_left = maxf(0.0, flash_time_left - delta)

	if recipes.is_brewing:
		feedback_label.text = "MIXING... %.1f" % recipes.brewing_time_left
		feedback_label.modulate = Color(0.85, 0.65, 1.0)
	elif feedback_time_left <= 0.0:
		feedback_label.text = ""

	if flash_time_left > 0.0:
		cauldron.modulate = Color.WHITE.lerp(
			flash_color, flash_time_left / 0.4
		)
	elif recipes.is_brewing:
		var pulse: float = (sin(effect_time * 10.0) + 1.0) * 0.5
		cauldron.modulate = Color.WHITE.lerp(
			Color(0.75, 0.5, 1.0), pulse * 0.65
		)
	else:
		cauldron.modulate = Color.WHITE