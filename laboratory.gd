extends Node2D
class_name Laboratory

signal location_changed(location_id: String)

@export var location_id := "laboratory"

const FLOOR_OUTLINE := [
	Vector2(310, 250),
	Vector2(1000, 250),
	Vector2(1060, 320),
	Vector2(1150, 390),
	Vector2(1150, 650),
	Vector2(170, 650),
	Vector2(170, 420),
	Vector2(250, 330)
]

var fire_sprite: Sprite2D
var fire_body: StaticBody2D
var fire_shape: ConvexPolygonShape2D
var previous_fire_size := Vector2.ZERO


func _ready() -> void:
	_disable_old_collisions()
	_create_floor_boundary()
	_create_water_collision()
	_create_fire_collision()

	call_deferred("_adjust_interaction_distances")
	location_changed.emit(location_id)


func _disable_old_collisions() -> void:
	var old_walls := get_node_or_null("Walls")

	if old_walls != null:
		for child in old_walls.get_children():
			var body := child as StaticBody2D
			if body != null:
				body.collision_layer = 0
				body.collision_mask = 0

	var old_table := get_node_or_null(
		"TableCollision"
	) as StaticBody2D

	if old_table != null:
		old_table.collision_layer = 0
		old_table.collision_mask = 0


func _create_floor_boundary() -> void:
	var boundary := StaticBody2D.new()
	boundary.name = "FloorBoundary"
	boundary.collision_layer = 1
	boundary.collision_mask = 0

	for index in range(FLOOR_OUTLINE.size()):
		var next_index: int = (
			(index + 1) % FLOOR_OUTLINE.size()
		)

		var segment := SegmentShape2D.new()
		segment.a = FLOOR_OUTLINE[index]
		segment.b = FLOOR_OUTLINE[next_index]

		var collision := CollisionShape2D.new()
		collision.shape = segment
		boundary.add_child(collision)

	add_child(boundary)


func _ellipse_points(
	radius_x: float,
	radius_y: float
) -> PackedVector2Array:
	var points := PackedVector2Array()

	for index in range(24):
		var angle: float = TAU * float(index) / 24.0
		points.append(Vector2(
			cos(angle) * radius_x,
			sin(angle) * radius_y
		))

	return points


func _create_water_collision() -> void:
	var body := StaticBody2D.new()
	body.name = "WaterObstacle"
	body.position = Vector2(1100, 415)
	body.collision_layer = 1
	body.collision_mask = 0

	var shape := ConvexPolygonShape2D.new()
	shape.points = _ellipse_points(70.0, 65.0)

	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)
	add_child(body)


func _create_fire_collision() -> void:
	fire_body = StaticBody2D.new()
	fire_body.name = "FireObstacle"
	fire_body.collision_layer = 1
	fire_body.collision_mask = 0

	fire_shape = ConvexPolygonShape2D.new()
	fire_shape.points = _ellipse_points(60.0, 80.0)

	var collision := CollisionShape2D.new()
	collision.shape = fire_shape
	fire_body.add_child(collision)
	add_child(fire_body)

	# Fire є сусіднім вузлом Laboratory у головній сцені.
	fire_sprite = get_parent().get_node_or_null(
		"Fire/FireSprite"
	) as Sprite2D

	# Спрайт може ще не завершити ініціалізацію.
	fire_body.collision_layer = 0


func _physics_process(_delta: float) -> void:
	if not is_instance_valid(fire_sprite):
		return

	if fire_sprite.texture == null:
		return

	var fire_system := fire_sprite.get_parent() as FireSystem

	if fire_system == null:
		return

	if fire_system.level <= 0.0 or not fire_sprite.is_visible_in_tree():
		fire_body.collision_layer = 0
		return

	fire_body.collision_layer = 1

	# Реальні розміри стікера після масштабування.
	var sprite_rect: Rect2 = fire_sprite.get_rect()
	var first_corner: Vector2 = to_local(
		fire_sprite.to_global(sprite_rect.position)
	)
	var last_corner: Vector2 = to_local(
		fire_sprite.to_global(sprite_rect.end)
	)

	var visual_size := Vector2(
		absf(last_corner.x - first_corner.x),
		absf(last_corner.y - first_corner.y)
	)

	# Перешкода охоплює основну частину полум'я.
	var center: Vector2 = (first_corner + last_corner) * 0.5
	center.y += visual_size.y * 0.08
	fire_body.position = center

	if not visual_size.is_equal_approx(previous_fire_size):
		previous_fire_size = visual_size
		fire_shape.points = _ellipse_points(
			maxf(20.0, visual_size.x * 0.43),
			maxf(25.0, visual_size.y * 0.43)
		)


func _adjust_interaction_distances() -> void:
	for node in get_tree().get_nodes_in_group("interactables"):
		var target := node as GameInteractable

		if target == null:
			continue

		if target.get_meta("dropped", false):
			continue

		match target.kind:
			GameInteractable.Kind.INGREDIENT:
				target.interaction_distance = 150.0
			GameInteractable.Kind.WATER:
				target.interaction_distance = 120.0
