extends CharacterBody2D
class_name CorePlayer

signal item_dropped(item_id: StringName, drop_position: Vector2)

@export var speed: float = 220.0

var inventory: PlayerInventory
var facing_direction: Vector2 = Vector2.DOWN
var held_item_sprite: Sprite2D
var item_textures: Dictionary = {}

@onready var witch_sprite: Sprite2D = $WitchSprite

var witch_down: Texture2D = preload(
	"res://assets/sprites/player/witch_down.png"
)
var witch_up: Texture2D = preload(
	"res://assets/sprites/player/witch_up.png"
)
var witch_left: Texture2D = preload(
	"res://assets/sprites/player/witch_left.png"
)
var witch_right: Texture2D = preload(
	"res://assets/sprites/player/witch_right.png"
)


func _ready() -> void:
	inventory = PlayerInventory.new()
	inventory.name = "Inventory"
	add_child(inventory)

	var old_body := get_node_or_null("Body") as CanvasItem
	if old_body != null:
		old_body.hide()

	var collision := $CollisionShape2D as CollisionShape2D
	var feet_shape := CircleShape2D.new()
	feet_shape.radius = 18.0
	collision.shape = feet_shape
	collision.position = Vector2(0, -12)

	collision_layer = 1
	collision_mask = 1

	held_item_sprite = Sprite2D.new()
	held_item_sprite.name = "HeldItemSprite"
	held_item_sprite.visible = false
	held_item_sprite.z_index = 1
	add_child(held_item_sprite)

	inventory.item_changed.connect(_on_item_changed)

	witch_sprite.texture = witch_down
	_align_sprite_to_feet()


func _align_sprite_to_feet() -> void:
	if witch_sprite.texture == null:
		return

	var sprite_height: float = (
		witch_sprite.texture.get_height()
		* absf(witch_sprite.scale.y)
	)

	witch_sprite.position = Vector2(0, -sprite_height * 0.5)
	_update_held_item_position()


func _on_item_changed(item_id: StringName) -> void:
	held_item_sprite.visible = false
	held_item_sprite.texture = null

	if item_id == &"":
		return

	var texture := _get_item_texture(item_id)

	if texture == null:
		return

	held_item_sprite.texture = texture

	var longest_side: float = maxf(
		float(texture.get_width()),
		float(texture.get_height())
	)

	if longest_side > 0.0:
		held_item_sprite.scale = Vector2.ONE * (
			38.0 / longest_side
		)

	held_item_sprite.visible = true
	_update_held_item_position()


func _get_item_texture(item_id: StringName) -> Texture2D:
	if item_textures.has(item_id):
		return item_textures[item_id] as Texture2D

	var path: String

	if item_id == &"water":
		path = "res://assets/sprites/objects/water.PNG"
	else:
		path = (
			"res://assets/sprites/ingredients/%s.png"
			% str(item_id)
		)

	if not ResourceLoader.exists(path):
		push_warning("Held item image not found: " + path)
		return null

	var texture := load(path) as Texture2D
	item_textures[item_id] = texture
	return texture


func _update_held_item_position() -> void:
	if held_item_sprite == null or witch_sprite.texture == null:
		return

	var sprite_height: float = (
		witch_sprite.texture.get_height()
		* absf(witch_sprite.scale.y)
	)
	var hand_height: float = -sprite_height * 0.43

	held_item_sprite.z_index = 1

	if absf(facing_direction.x) > absf(facing_direction.y):
		var side: float = -1.0 if facing_direction.x < 0.0 else 1.0
		held_item_sprite.position = Vector2(
			32.0 * side,
			hand_height
		)
	elif facing_direction.y < 0.0:
		# Коли відьмочка повернута спиною,
		# предмет частково ховається за нею.
		held_item_sprite.position = Vector2(28, hand_height - 5.0)
		held_item_sprite.z_index = -1
	else:
		held_item_sprite.position = Vector2(22, hand_height)


func update_witch_direction(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return

	if absf(direction.x) > absf(direction.y):
		witch_sprite.texture = (
			witch_left if direction.x < 0 else witch_right
		)
	else:
		witch_sprite.texture = (
			witch_up if direction.y < 0 else witch_down
		)

	_align_sprite_to_feet()


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
	_update_depth()


func _update_depth() -> void:
	z_index = 5

	for node in get_tree().get_nodes_in_group("interactables"):
		var target := node as GameInteractable

		if target == null or not target.is_visible_in_tree():
			continue

		if target.kind == GameInteractable.Kind.CAULDRON:
			if global_position.y < target.global_position.y + 55.0:
				z_index = 3
			return


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
	var nearest: GameInteractable = null
	var nearest_distance: float = INF
	var nearby_cauldron: GameInteractable = null

	for node in get_tree().get_nodes_in_group("interactables"):
		var target := node as GameInteractable

		if target == null or not target.can_interact(self):
			continue

		var distance: float = global_position.distance_to(
			target.get_interaction_position()
		)

		if (
			inventory.has_item()
			and target.kind == GameInteractable.Kind.CAULDRON
		):
			nearby_cauldron = target

		if distance < nearest_distance:
			nearest = target
			nearest_distance = distance

	if nearby_cauldron != null:
		nearby_cauldron.interact(self)
	elif nearest != null:
		nearest.interact(self)


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
	witch_sprite.texture = witch_down
	_align_sprite_to_feet()
	_update_depth()