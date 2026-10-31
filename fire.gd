extends Node2D
class_name FireSystem

signal fire_changed(value: float)
signal fire_maxed

@export var level: float = 20.0
@export var min_fire_size: float = 200.0
@export var max_fire_size: float = 320.0

@onready var flame: Polygon2D = get_node_or_null("Flame")
@onready var light: PointLight2D = get_node_or_null("PointLight2D")
@onready var fire_sprite: AnimatedSprite2D = get_node_or_null("FireSprite")

const SPREAD_POSITIONS := [
	Vector2(-260.0, -35.0),
	Vector2(-510.0, -170.0),
	Vector2(-760.0, -80.0),
	Vector2(-470.0, 55.0),
	Vector2(-110.0, -220.0),
	Vector2(-760.0, -260.0)
]

const SPREAD_LEVELS := [25.0, 40.0, 55.0, 70.0, 85.0, 95.0]

var animation_time: float = 0.0
var effects_visible: bool = false
var _has_emitted_max: bool = false
var spread_sprites: Array[AnimatedSprite2D] = []


func _ready() -> void:
	z_index = 2

	if flame != null:
		flame.hide()
	if fire_sprite != null:
		fire_sprite.modulate = Color.WHITE
		fire_sprite.animation = &"burn"
		fire_sprite.play()

	_create_spread_flames()
	set_level(level)


func increase(amount: float) -> void:
	set_level(level + amount)


func decrease(amount: float) -> void:
	set_level(level - amount)


func set_level(value: float) -> void:
	level = clampf(value, 0.0, 100.0)
	update_fire_visual()
	_update_spread_flames()

	if light != null:
		light.energy = 0.35 + level / 100.0
		light.visible = level > 0.0

	fire_changed.emit(level)

	if level >= 100.0 and not _has_emitted_max:
		_has_emitted_max = true
		fire_maxed.emit()
	elif level < 100.0:
		_has_emitted_max = false

	queue_redraw()


func _create_spread_flames() -> void:
	if fire_sprite == null or fire_sprite.sprite_frames == null:
		return

	for index in range(SPREAD_POSITIONS.size()):
		var spread_sprite := AnimatedSprite2D.new()
		spread_sprite.name = "SpreadFire%d" % index
		spread_sprite.sprite_frames = fire_sprite.sprite_frames
		spread_sprite.animation = &"burn"
		spread_sprite.position = SPREAD_POSITIONS[index]
		spread_sprite.modulate = Color(1.0, 1.0, 1.0, 0.0)
		spread_sprite.z_index = fire_sprite.z_index
		spread_sprite.play()
		add_child(spread_sprite)
		spread_sprites.append(spread_sprite)


func _update_spread_flames() -> void:
	for index in range(spread_sprites.size()):
		var spread_sprite := spread_sprites[index]
		var unlocked: bool = level >= SPREAD_LEVELS[index]
		spread_sprite.modulate.a = 1.0 if unlocked else 0.0

		if unlocked:
			var texture := spread_sprite.sprite_frames.get_frame_texture(
				&"burn",
				0
			)
			if texture == null:
				continue

			var longest_side: float = maxf(
				texture.get_width(),
				texture.get_height()
			)
			var size: float = lerpf(
				105.0,
				185.0,
				level / 100.0
			)

			if longest_side > 0.0:
				spread_sprite.scale = Vector2.ONE * (
					size / longest_side
				)


func update_fire_visual() -> void:
	if fire_sprite == null:
		return

	if fire_sprite.sprite_frames == null:
		return

	if not fire_sprite.sprite_frames.has_animation(&"burn"):
		return

	fire_sprite.visible = level > 0.0

	var texture: Texture2D = (
		fire_sprite.sprite_frames.get_frame_texture(
			&"burn",
			0
		)
	)

	if texture == null:
		return

	var texture_size: Vector2 = texture.get_size()

	var longest_side: float = maxf(
		texture_size.x,
		texture_size.y
	)

	if longest_side <= 0.0:
		return

	var target_size: float = lerpf(
		min_fire_size,
		max_fire_size,
		level / 100.0
	)

	fire_sprite.scale = Vector2.ONE * (
		target_size / longest_side
	)

func _process(delta: float) -> void:
	var manager := get_parent() as GameManager

	if manager == null:
		return

	effects_visible = (
		manager.state != GameManager.GameState.MENU
		and level > 0.0
	)

	if manager.state == GameManager.GameState.PLAYING:
		animation_time += delta

	if fire_sprite != null:
		if manager.state == GameManager.GameState.PLAYING and level > 0.0:
			fire_sprite.speed_scale = 1.0
		else:
			fire_sprite.speed_scale = 0.0

		for index in range(spread_sprites.size()):
			var spread_sprite := spread_sprites[index]
			spread_sprite.speed_scale = fire_sprite.speed_scale
			if spread_sprite.modulate.a > 0.0:
				var phase: float = float(index) * 1.7
				spread_sprite.rotation = sin(
					animation_time * 2.5 + phase
				) * 0.08

		queue_redraw()


func _room_point(point: Vector2) -> Vector2:
	return to_local(get_parent().to_global(point))


func _draw() -> void:
	if not effects_visible:
		return

	var danger: float = clampf(
		(level - 20.0) / 80.0,
		0.0,
		1.0
	)

	var pulse: float = (
		0.9 + sin(animation_time * 3.0) * 0.1
	)

	# Дуже слабкий теплий відтінок кімнати.
	draw_rect(
		Rect2(_room_point(Vector2.ZERO), Vector2(1280, 720)),
		Color(1.0, 0.25, 0.06, danger * 0.07 * pulse)
	)

	# Дим піднімається біля основного вогню.
	_draw_smoke_column(
		Vector2(1000, 585),
		0.0,
		clampf(level / 50.0, 0.0, 1.0)
	)

	# При сильній пожежі дим з'являється біля країв.
	if danger > 0.0:
		_draw_smoke_column(
			Vector2(1190, 510),
			1.7,
			danger
		)
		_draw_smoke_column(
			Vector2(180, 560),
			3.2,
			danger * 0.7
		)

	_draw_sparks(danger)


func _draw_smoke_column(
	base: Vector2,
	phase_offset: float,
	strength: float
) -> void:
	for index in range(9):
		var phase: float = fposmod(
			animation_time * 0.12
			+ float(index) / 9.0
			+ phase_offset,
			1.0
		)

		var drift: float = sin(
			phase * 4.0 + phase_offset
		) * (15.0 + phase * 45.0)

		var point: Vector2 = base + Vector2(
			drift,
			-phase * 350.0
		)

		var radius: float = 12.0 + phase * 44.0
		var opacity: float = (
			sin(phase * PI) * strength * 0.075
		)

		# Кілька прозорих кіл пом'якшують край диму.
		for ring in range(3):
			draw_circle(
				_room_point(point),
				radius * (1.0 - float(ring) * 0.18),
				Color(0.15, 0.12, 0.19, opacity * 0.45)
			)


func _draw_sparks(danger: float) -> void:
	var spark_count: int = 8 + int(danger * 16.0)

	for index in range(spark_count):
		var seed_value: float = float(index) * 2.39

		var phase: float = fposmod(
			animation_time * (
				0.22 + float(index % 5) * 0.025
			) + seed_value,
			1.0
		)

		var spread: float = 45.0 + danger * 130.0

		var point := Vector2(
			1000.0
			+ sin(seed_value) * spread
			+ sin(phase * 5.0 + seed_value) * 18.0,
			610.0 - phase * (220.0 + danger * 200.0)
		)

		var opacity: float = (
			sin(phase * PI) * 0.8
		)

		draw_line(
			_room_point(point),
			_room_point(point + Vector2(1.0, 3.0)),
			Color(1.0, 0.75, 0.3, opacity),
			1.5,
			true
		)
