
extends CharacterBody2D
class_name CorePlayer

signal item_dropped(item_id: StringName, drop_position: Vector2)

@export var speed: float = 220.0

var inventory: PlayerInventory
var facing_direction: Vector2 = Vector2.DOWN

@onready var witch_sprite: AnimatedSprite2D = $WitchSprite
@export var walking_scale_multiplier: float = 1.4

var normal_sprite_scale: Vector2

func _ready() -> void:
	inventory = PlayerInventory.new()
	inventory.name = "Inventory"
	add_child(inventory)
	normal_sprite_scale = witch_sprite.scale

	witch_sprite.play("idle_down")


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

	update_witch_animation(direction)


func update_witch_animation(direction: Vector2) -> void:
	var animation_name: String = ""

	var is_moving: bool = direction != Vector2.ZERO

	var look_direction: Vector2 = facing_direction

	if absf(look_direction.x) > absf(look_direction.y):
		if look_direction.x < 0:
			animation_name = "left"
		else:
			animation_name = "right"
	else:
		if look_direction.y < 0:
			animation_name = "up"
		else:
			animation_name = "down"

	if is_moving:
		animation_name = "walk_" + animation_name
	else:
		animation_name = "idle_" + animation_name
	if is_moving:
		witch_sprite.scale = normal_sprite_scale * walking_scale_multiplier
	else:
		witch_sprite.scale = normal_sprite_scale
	if witch_sprite.animation != animation_name:
		witch_sprite.play(animation_name)
	elif not witch_sprite.is_playing():
		witch_sprite.play()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		interact_with_nearest()

	elif event.is_action_pressed("drop_item"):
		drop_held_item()


func interact_with_nearest() -> void:
	var nearest: GameInteractable = null
	var nearest_distance: float = INF
	var nearby_cauldron: GameInteractable = null

	for node in get_tree().get_nodes_in_group("interactables"):
		var target := node as GameInteractable

		if target == null or not target.is_visible_in_tree():
			continue

		if not target.can_interact(self):
			continue

		var distance: float = global_position.distance_to(
			target.global_position
		)

		if inventory.has_item() and target.kind == GameInteractable.Kind.CAULDRON:
			nearby_cauldron = target

		if distance < nearest_distance:
			nearest = target
			nearest_distance = distance

	if nearby_cauldron != null:
		nearby_cauldron.interact(self)
		return

	if nearest != null:
		nearest.interact(self)


func drop_held_item() -> void:
	if inventory == null or not inventory.has_item():
		return

	var item_id: StringName = inventory.remove_item()

	var drop_position: Vector2 = global_position + facing_direction * 48.0

	item_dropped.emit(item_id, drop_position)


func reset_player() -> void:
	velocity = Vector2.ZERO
	facing_direction = Vector2.DOWN

	if inventory != null:
		inventory.reset()

	witch_sprite.play("idle_down")
