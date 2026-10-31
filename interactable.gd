extends Node2D
class_name GameInteractable

signal interacted(target: GameInteractable, actor: Node)

enum Kind { INGREDIENT, WATER, CAULDRON, FIRE }

@export var kind: Kind = Kind.INGREDIENT
@export var item_id: StringName = &"mushroom"
@export var display_name: String = "Mushroom"
@export var object_color: Color = Color(0.7, 0.3, 0.8)
@export var interaction_distance: float = 70.0

const CAULDRON_VISUAL_CENTER := Vector2(0, -40)
const CAULDRON_BODY_CENTER := Vector2(0, 20)

var visual_sprite: Sprite2D = null


func _ready() -> void:
	add_to_group("interactables")
	if kind == Kind.FIRE:
		return
	_setup_visual_sprite()

	if kind == Kind.CAULDRON:
		z_index = 4
		_setup_cauldron_collision()
	else:
		z_index = 1

		if get_meta("dropped", false):
			_setup_dropped_item_collision()

	var caption := Label.new()
	caption.text = display_name
	caption.size = Vector2(130, 30)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE

	match kind:
		Kind.CAULDRON:
			caption.position = Vector2(-65, 90)
		Kind.WATER:
			caption.position = Vector2(-65, 40)
		_:
			caption.position = Vector2(-65, 28)

	add_child(caption)
	queue_redraw()


func _setup_visual_sprite() -> void:
	var image_path: String = ""
	var target_size: float = 48.0

	match kind:
		Kind.INGREDIENT:
			if item_id == &"water":
				image_path = "res://assets/sprites/objects/water.PNG"
			else:
				image_path = (
					"res://assets/sprites/ingredients/%s.png"
					% str(item_id)
				)

		Kind.CAULDRON:
			image_path = "res://assets/sprites/objects/cauldron.png"
			target_size = 250.0

		Kind.WATER:
			image_path = "res://assets/sprites/objects/water.PNG"
			target_size = 150.0

	if not ResourceLoader.exists(image_path):
		push_warning("Image not found: " + image_path)
		return

	var texture := load(image_path) as Texture2D
	if texture == null:
		return

	visual_sprite = Sprite2D.new()
	visual_sprite.name = "VisualSprite"
	visual_sprite.texture = texture
	visual_sprite.centered = true

	var longest_side: float = maxf(
		float(texture.get_width()),
		float(texture.get_height())
	)

	if longest_side > 0.0:
		visual_sprite.scale = Vector2.ONE * (
			target_size / longest_side
		)

	if kind == Kind.CAULDRON:
		visual_sprite.position = CAULDRON_VISUAL_CENTER
	elif kind == Kind.WATER:
		visual_sprite.position = Vector2(0, -18)

	add_child(visual_sprite)


func _setup_cauldron_collision() -> void:
	var body := StaticBody2D.new()
	body.name = "CauldronBody"
	body.position = CAULDRON_BODY_CENTER
	body.collision_layer = 1
	body.collision_mask = 0

	var collision := CollisionShape2D.new()
	collision.name = "CauldronCollision"

	var shape := ConvexPolygonShape2D.new()
	var points := PackedVector2Array()

	for index in range(24):
		var angle: float = TAU * float(index) / 24.0
		points.append(Vector2(
			cos(angle) * 100.0,
			sin(angle) * 65.0
		))

	shape.points = points
	collision.shape = shape

	body.add_child(collision)
	add_child(body)


func _setup_dropped_item_collision() -> void:
	var body := StaticBody2D.new()
	body.name = "DroppedItemBody"
	body.collision_layer = 1
	body.collision_mask = 0

	var shape := CircleShape2D.new()
	shape.radius = 20.0

	var collision := CollisionShape2D.new()
	collision.name = "DroppedItemCollision"
	collision.shape = shape

	body.add_child(collision)
	add_child(body)


func get_interaction_position() -> Vector2:
	if kind == Kind.CAULDRON:
		return to_global(CAULDRON_BODY_CENTER)

	return global_position


func can_interact(actor: Node2D) -> bool:
	if not is_instance_valid(actor) or not is_visible_in_tree():
		return false

	var allowed_distance: float = interaction_distance

	if kind == Kind.FIRE:
		allowed_distance = maxf(allowed_distance, 220.0)

	if kind == Kind.CAULDRON:
		allowed_distance = maxf(allowed_distance, 150.0)

	return (
		get_interaction_position().distance_to(actor.global_position)
		<= allowed_distance
	)


func interact(actor: Node2D) -> void:
	if can_interact(actor):
		interacted.emit(self, actor)


func _draw() -> void:
	if visual_sprite != null:
		return

	var radius: float = 20.0
	var center := Vector2.ZERO

	if kind == Kind.CAULDRON:
		radius = 65.0
		center = CAULDRON_VISUAL_CENTER

	draw_circle(center, radius, object_color)
	draw_arc(center, radius, 0.0, TAU, 40, Color.WHITE, 2.0)
