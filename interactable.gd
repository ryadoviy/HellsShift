
extends Node2D
class_name GameInteractable

signal interacted(target: GameInteractable, actor: Node)

enum Kind { INGREDIENT, WATER, CAULDRON }

@export var kind: Kind = Kind.INGREDIENT
@export var item_id: StringName = &"mushroom"
@export var display_name: String = "Mushroom"
@export var object_color: Color = Color(0.7, 0.3, 0.8)
@export var interaction_distance: float = 70.0

var visual_sprite: Sprite2D = null


func _ready() -> void:
	add_to_group("interactables")

	if kind == Kind.INGREDIENT or kind == Kind.CAULDRON or kind == Kind.WATER:
		_setup_visual_sprite()


	if kind == Kind.CAULDRON:
		_setup_cauldron_collision()

	var caption := Label.new()
	caption.text = display_name

	
	if kind == Kind.CAULDRON:
		caption.position = Vector2(-65, 52)
	elif kind == Kind.WATER:
		caption.position = Vector2(-55, 40)
	else:
		caption.position = Vector2(-65, 28)


	caption.size = Vector2(130, 30)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(caption)
	queue_redraw()


func _setup_visual_sprite() -> void:
	var image_path := ""
	var target_size: float = 48.0

	match kind:
		Kind.INGREDIENT:
			image_path = (
                "res://assets/sprites/ingredients/%s.png"
				% str(item_id)
			)
			target_size = 48.0

		Kind.CAULDRON:
			image_path = "res://assets/sprites/objects/cauldron.png"
			target_size = 250.0
		
		Kind.WATER:
			image_path = "res://assets/sprites/objects/water.png"
			target_size = 150.0


		_:
			return

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
		var scale_factor: float = target_size / longest_side
		visual_sprite.scale = Vector2(
			scale_factor,
			scale_factor
		)

	if kind == Kind.CAULDRON:
		visual_sprite.position = Vector2(0, -40)
	elif kind == Kind.WATER:
		visual_sprite.position = Vector2(0, -18)

	add_child(visual_sprite)


func _setup_cauldron_collision() -> void:
	var body := StaticBody2D.new()
	body.name = "CauldronBody"

	body.collision_layer = 1
	body.collision_mask = 0

	var collision := CollisionShape2D.new()
	collision.name = "CauldronCollision"
	collision.position = Vector2(0, -120)

	var shape := CircleShape2D.new()
	shape.radius = 80.0

	collision.shape = shape
	body.add_child(collision)
	add_child(body)

func can_interact(actor: Node2D) -> bool:
	return (
		global_position.distance_to(actor.global_position)
		<= interaction_distance
	)


func interact(actor: Node2D) -> void:
	if can_interact(actor):
		interacted.emit(self, actor)


func _draw() -> void:
	if visual_sprite != null:
		return

	var radius: float = (
		35.0 if kind == Kind.CAULDRON else 20.0
	)

	draw_circle(
		Vector2.ZERO,
		radius,
		object_color
	)

	draw_arc(
		Vector2.ZERO,
		radius,
		0.0,
		TAU,
		40,
		Color.WHITE,
		2.0
	)
