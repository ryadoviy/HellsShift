extends CharacterBody2D
class_name CorePlayer

signal item_dropped(item_id: StringName, drop_position: Vector2)

@export var speed: float = 220.0

var inventory: PlayerInventory
var facing_direction: Vector2 = Vector2.DOWN


func _ready() -> void:
	inventory = PlayerInventory.new()
	inventory.name = "Inventory"
	add_child(inventory)


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


func _unhandled_input(event: InputEvent) -> void:
	if not is_physics_processing() or event.is_echo():
		return

	if event.is_action_pressed("interact"):
		interact_with_nearest()
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("drop_item"):
		drop_held_item()
		get_viewport().set_input_as_handled()


# Знайти найближчий доступний об'єкт.
func interact_with_nearest() -> void:
	var nearest: GameInteractable = null
	var nearest_distance: float = INF

	for node in get_tree().get_nodes_in_group("interactables"):
		var target := node as GameInteractable

		if target == null or not target.is_visible_in_tree():
			continue

		if not target.can_interact(self):
			continue

		var distance := global_position.distance_to(
			target.global_position
		)

		if distance < nearest_distance:
			nearest = target
			nearest_distance = distance

	if nearest != null:
		nearest.interact(self)


# Скинути предмет із рук.
func drop_held_item() -> void:
	if not inventory.has_item():
		return

	var item_id := inventory.remove_item()
	var drop_position := global_position + facing_direction * 40.0
	item_dropped.emit(item_id, drop_position)


# Очистити стан гравця перед новим раундом.
func reset_player() -> void:
	velocity = Vector2.ZERO
	facing_direction = Vector2.DOWN
	inventory.reset()