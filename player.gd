extends CharacterBody2D
class_name CorePlayer

signal item_dropped(item_id: StringName, drop_position: Vector2)

@export var speed: float = 220.0
@export var walking_scale_multiplier: float = 1.4

var inventory: PlayerInventory
var facing_direction: Vector2 = Vector2.DOWN

var held_item_sprite: Sprite2D
var item_textures: Dictionary = {}
var normal_sprite_scale: Vector2

@onready var witch_sprite: AnimatedSprite2D = $WitchSprite


func _ready() -> void:
	inventory = PlayerInventory.new()
	inventory.name = "Inventory"
	add_child(inventory)

	normal_sprite_scale = witch_sprite.scale

	var old_body := get_node_or_null("Body") as CanvasItem
	if old_body != null:
		old_body.hide()

	# Колізія біля ніг персонажа.
	var collision := $CollisionShape2D as CollisionShape2D
	var feet_shape := CircleShape2D.new()
	feet_shape.radius = 18.0
	collision.shape = feet_shape
	collision.position = Vector2(0, -12)

	collision_layer = 1
	collision_mask = 1

	# Спрайт предмета, який персонаж тримає в руках.
	held_item_sprite = Sprite2D.new()
	held_item_sprite.name = "HeldItemSprite"
	held_item_sprite.visible = false
	held_item_sprite.z_index = 1
	add_child(held_item_sprite)

	inventory.item_changed.connect(_on_item_changed)

	witch_sprite.play("idle_down")
	_align_sprite_to_feet()
	_update_depth()


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
	_align_sprite_to_feet()
	_update_depth()


# Повертає текстуру поточного кадру AnimatedSprite2D.
func _get_current_witch_texture() -> Texture2D:
	if witch_sprite.sprite_frames == null:
		return null

	var animation: StringName = witch_sprite.animation

	if not witch_sprite.sprite_frames.has_animation(animation):
		return null

	var count := witch_sprite.sprite_frames.get_frame_count(animation)

	if count == 0:
		return null

	var frame_index := clampi(witch_sprite.frame, 0, count - 1)

	return witch_sprite.sprite_frames.get_frame_texture(
		animation,
		frame_index
	)


func _get_witch_height() -> float:
	var texture := _get_current_witch_texture()

	if texture == null:
		return 0.0

	return float(texture.get_height()) * absf(witch_sprite.scale.y)


func _align_sprite_to_feet() -> void:
	var sprite_height := _get_witch_height()

	if sprite_height <= 0.0:
		return

	witch_sprite.position = Vector2(0, -sprite_height * 0.5)
	_update_held_item_position()


func update_witch_animation(direction: Vector2) -> void:
	var look_direction := facing_direction
	var suffix := ""

	if absf(look_direction.x) > absf(look_direction.y):
		suffix = "left" if look_direction.x < 0.0 else "right"
	else:
		suffix = "up" if look_direction.y < 0.0 else "down"

	var is_moving := direction != Vector2.ZERO
	var animation_name := (
		"walk_" + suffix if is_moving else "idle_" + suffix
	)

	if is_moving:
		witch_sprite.scale = normal_sprite_scale * walking_scale_multiplier
	else:
		witch_sprite.scale = normal_sprite_scale

	if witch_sprite.animation != animation_name:
		witch_sprite.play(animation_name)
	elif not witch_sprite.is_playing():
		witch_sprite.play()


# Оновлює предмет у руках після зміни інвентаря.
func _on_item_changed(item_id: StringName) -> void:
	held_item_sprite.visible = false
	held_item_sprite.texture = null

	if item_id == &"":
		return

	var texture := _get_item_texture(item_id)

	if texture == null:
		return

	held_item_sprite.texture = texture

	var longest_side := maxf(
		float(texture.get_width()),
		float(texture.get_height())
	)

	if longest_side > 0.0:
		held_item_sprite.scale = Vector2.ONE * (38.0 / longest_side)

	held_item_sprite.visible = true
	_update_held_item_position()


func _get_item_texture(item_id: StringName) -> Texture2D:
	if item_textures.has(item_id):
		return item_textures[item_id] as Texture2D

	var path: String

	if item_id == &"water":
		path = "res://assets/sprites/objects/water.png"
	else:
		path = "res://assets/sprites/ingredients/%s.png" % str(item_id)

	if not ResourceLoader.exists(path):
		push_warning("Held item image not found: " + path)
		return null

	var texture := load(path) as Texture2D
	if texture == null:
		push_warning("Could not load held item image: " + path)
		return null

	item_textures[item_id] = texture
	return texture


func _update_held_item_position() -> void:
	if held_item_sprite == null:
		return

	var sprite_height := _get_witch_height()
	if sprite_height <= 0.0:
		return

	var hand_height := -sprite_height * 0.43
	held_item_sprite.z_index = 1

	if absf(facing_direction.x) > absf(facing_direction.y):
		var side := -1.0 if facing_direction.x < 0.0 else 1.0
		held_item_sprite.position = Vector2(32.0 * side, hand_height)

	elif facing_direction.y < 0.0:
		held_item_sprite.position = Vector2(28.0, hand_height - 5.0)
		held_item_sprite.z_index = -1

	else:
		held_item_sprite.position = Vector2(22.0, hand_height)


# Визначає порядок відображення персонажа відносно казана.
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
	if event.is_action_pressed("interact"):
		interact_with_nearest()
	elif event.is_action_pressed("drop_item"):
		drop_held_item()


func interact_with_nearest() -> void:
	var nearest_item: GameInteractable = null
	var nearest_item_distance: float = INF
	var nearby_cauldron: GameInteractable = null
	var cauldron_distance: float = INF

	for node in get_tree().get_nodes_in_group("interactables"):
		var target := node as GameInteractable

		if target == null or not target.is_visible_in_tree():
			continue

		if not target.can_interact(self):
			continue

		var distance := global_position.distance_to(
			target.get_interaction_position()
		)

		if inventory.has_item():
			# Коли руки зайняті, предмет можна використати на казані.
			if target.kind == GameInteractable.Kind.CAULDRON:
				if distance < cauldron_distance:
					nearby_cauldron = target
					cauldron_distance = distance
		else:
			# З порожніми руками шукаємо найближчий інгредієнт або воду.
			if target.kind != GameInteractable.Kind.CAULDRON:
				if distance < nearest_item_distance:
					nearest_item = target
					nearest_item_distance = distance

	if inventory.has_item():
		if nearby_cauldron != null:
			nearby_cauldron.interact(self)
	else:
		if nearest_item != null:
			nearest_item.interact(self)


func drop_held_item() -> void:
	if inventory == null or not inventory.has_item():
		return

	var item_id: StringName = inventory.remove_item()
	var drop_position := global_position + facing_direction * 48.0
	item_dropped.emit(item_id, drop_position)


func reset_player() -> void:
	velocity = Vector2.ZERO
	facing_direction = Vector2.DOWN

	if inventory != null:
		inventory.reset()

	witch_sprite.scale = normal_sprite_scale
	witch_sprite.play("idle_down")

	_align_sprite_to_feet()
	_update_depth()
