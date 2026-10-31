extends Node2D
class_name GameInteractable

const UI_FONT := preload("res://assets/fonts/MedievalSharp-Regular.ttf")
const SAFE_ZONE_TEXTURE := preload(
	"res://assets/sprites/objects/safe_point_pumpkin.jpg"
)

signal interacted(target: GameInteractable, actor: Node)

enum Kind { INGREDIENT, WATER, CAULDRON, FIRE, SAFE_ZONE }

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
	caption.add_theme_font_override("font", UI_FONT)

	match kind:
		Kind.CAULDRON:
			caption.position = Vector2(-65, 90)
		Kind.WATER:
			caption.position = Vector2(-65, 40)
		Kind.SAFE_ZONE:
			caption.text = "SAFE POINT"
			caption.position = Vector2(-70, 52)
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
		Kind.SAFE_ZONE:
			target_size = 115.0

	if kind == Kind.SAFE_ZONE:
		visual_sprite = Sprite2D.new()
		visual_sprite.name = "VisualSprite"
		visual_sprite.texture = SAFE_ZONE_TEXTURE
		visual_sprite.centered = true
		visual_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		visual_sprite.material = _create_safe_zone_material()
	else:
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
		float(visual_sprite.texture.get_width()),
		float(visual_sprite.texture.get_height())
	)

	if longest_side > 0.0:
		visual_sprite.scale = Vector2.ONE * (
			target_size / longest_side
		)

	if kind == Kind.CAULDRON:
		visual_sprite.position = CAULDRON_VISUAL_CENTER
	elif kind == Kind.WATER:
		visual_sprite.position = Vector2(0, -18)
	elif kind == Kind.SAFE_ZONE:
		visual_sprite.position = Vector2(0, -10)

	add_child(visual_sprite)


func _create_safe_zone_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
render_mode unshaded;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float whiteness = min(source.r, min(source.g, source.b));
	float alpha = 1.0 - smoothstep(0.88, 0.98, whiteness);
	COLOR = vec4(source.rgb, source.a * alpha);
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


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
	elif kind == Kind.SAFE_ZONE:
		allowed_distance = maxf(allowed_distance, 120.0)

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
