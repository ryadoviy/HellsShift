extends CharacterBody2D
class_name CorePlayer

signal item_dropped(item_id: StringName, drop_position: Vector2)

@export var speed: float = 220.0

var inventory: PlayerInventory
var facing_direction: Vector2 = Vector2.DOWN

@onready var witch_sprite: Sprite2D = $WitchSprite

var witch_down: Texture2D = preload("res://assets/sprites/player/witch_down.png")
var witch_up: Texture2D = preload("res://assets/sprites/player/witch_up.png")
var witch_left: Texture2D = preload("res://assets/sprites/player/witch_left.png")
var witch_right: Texture2D = preload("res://assets/sprites/player/witch_right.png")


func update_witch_direction(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return

	if absf(direction.x) > absf(direction.y):
		if direction.x < 0:
			witch_sprite.texture = witch_left
		else:
			witch_sprite.texture = witch_right
	else:
		if direction.y < 0:
			witch_sprite.texture = witch_up
		else:
			witch_sprite.texture = witch_down


func _ready() -> void:
	inventory = PlayerInventory.new()
	inventory.name = "Inventory"
	add_child(inventory)

	# Початковий вигляд — обличчям до гравця
	witch_sprite.texture = witch_down


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	if direction != Vector2.ZERO:
		facing_direction = direction.normalized()

	velocity = direction * speed
	move_and_slide()
	update_witch_direction(direction)


func _unhandled_input(event: InputEvent) -> void:
	if not is_physics_processing() or event.is_echo():
		return

	if event.is_action_pressed("interact"):
		interact_with_nearest()
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("drop_item"):
		drop_held_item()
		get_viewport().set_input_as_handled()



func interact_with_nearest() -> void:
	for node in get_tree().get_nodes_in_group("interactables"):
		var target := node as GameInteractable

		if target != null and target.kind == GameInteractable.Kind.CAULDRON:
			print("DISTANCE TO CAULDRON: ",
				global_position.distance_to(target.global_position))
			print("ALLOWED DISTANCE: ", target.interaction_distance)
	print("E PRESSED — SEARCHING FOR INTERACTABLE")
	var nearest: GameInteractable = null
	var nearest_distance: float = INF
	var nearby_cauldron: GameInteractable = null

	for node in get_tree().get_nodes_in_group("interactables"):
		var target := node as GameInteractable

		if target == null or not target.is_visible_in_tree():
			continue

		if not target.can_interact(self):
			continue

		var distance := global_position.distance_to(
			target.global_position
		)

		if inventory.has_item() and target.kind == GameInteractable.Kind.CAULDRON:
			nearby_cauldron = target

		if distance < nearest_distance:
			nearest = target
			nearest_distance = distance

	if nearby_cauldron != null:
		print("CAULDRON SELECTED")
		nearby_cauldron.interact(self)
		return

	if nearest != null:
		print("SELECTED: ", nearest.display_name)
		nearest.interact(self)

# Скинути предмет із рук.
func drop_held_item() -> void:
	if not inventory.has_item():
		return

	var item_id := inventory.remove_item()
	var drop_position := global_position + facing_direction * 40.0
	item_dropped.emit(item_id, drop_position)


func reset_player() -> void:
	velocity = Vector2.ZERO
	facing_direction = Vector2.DOWN
	inventory.reset()

	# Повертаємо відьмочку обличчям до гравця
	witch_sprite.texture = witch_down
