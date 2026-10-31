
extends Node2D
class_name GhostSabotage

enum Phase { FLYING, LEAVING }

@export var ghost_size: float = 150.0
@export var ghost_fps: float = 6.0

var spawn_interval: float = 25.0
var max_ghosts: int = 2
var block_duration: float = 3.0
var hunt_duration: float = 5.0
var flight_speed: float = 180.0

var objects: Node2D
var player: CorePlayer
var ghosts: Array[Dictionary] = []
var spawn_time_left: float = 8.0
var animation_time: float = 0.0

var ghost_animations: Array[SpriteFrames] = []


func _ready() -> void:
	_load_ghost_animations()


func setup(gameplay_objects: Node2D) -> void:
	objects = gameplay_objects
	z_index = 6
	visible = true

	if ghost_animations.is_empty():
		_load_ghost_animations()


func set_player(target: CorePlayer) -> void:
	player = target


func _load_ghost_animations() -> void:
	ghost_animations.clear()

	for ghost_number in range(1, 4):
		var frames := SpriteFrames.new()
		frames.add_animation("fly")
		frames.set_animation_speed("fly", ghost_fps)
		frames.set_animation_loop("fly", true)

		# Прибираємо стандартну непотрібну анімацію
		if frames.has_animation("default"):
			frames.remove_animation("default")

		for frame_number in range(1, 4):
			var path := (
                "res://assets/sprites/ghosts/ghost_%d/%02d.png"
				% [ghost_number, frame_number]
			)

			if not ResourceLoader.exists(path):
				push_warning("Ghost image not found: " + path)
				continue

			var texture := load(path) as Texture2D

			if texture != null:
				frames.add_frame("fly", texture)

		if frames.get_frame_count("fly") > 0:
			ghost_animations.append(frames)

	print("Loaded ghost animations: ", ghost_animations.size())


func configure(
	interval: float,
	limit: int,
	duration: float,
	hunt_time: float
) -> void:
	spawn_interval = maxf(1.0, interval)
	max_ghosts = clampi(limit, 0, 6)
	block_duration = maxf(0.1, duration)
	hunt_duration = maxf(0.1, hunt_time)


func reset() -> void:
	for ghost in ghosts:
		_remove_ghost_sprite(ghost)

	ghosts.clear()
	spawn_time_left = minf(3.0, spawn_interval)
	animation_time = 0.0
	queue_redraw()


func advance(delta: float) -> void:
	if objects == null:
		return

	animation_time += delta
	spawn_time_left -= delta

	if spawn_time_left <= 0.0:
		spawn_time_left = spawn_interval
		while ghosts.size() < max_ghosts and spawn_ghost():
			pass

	for index in range(ghosts.size() - 1, -1, -1):
		var ghost: Dictionary = ghosts[index]
		var position: Vector2 = ghost["position"]
		var phase: int = int(ghost["phase"])

		match phase:
			Phase.FLYING:
				if player == null:
					continue

				var destination := to_local(player.global_position)

				position = position.move_toward(
					destination,
					flight_speed * delta
				)
				ghost["position"] = position
				ghost["hunt_time_left"] = maxf(
					0.0,
					float(ghost["hunt_time_left"]) - delta
				)

				if float(ghost["hunt_time_left"]) <= 0.0:
					ghost["phase"] = Phase.LEAVING

			Phase.LEAVING:
				var exit_position: Vector2 = ghost["exit"]

				position = position.move_toward(
					exit_position,
					flight_speed * delta
				)
				ghost["position"] = position

				if position.distance_to(exit_position) < 2.0:
					_remove_ghost_sprite(ghost)
					ghosts.remove_at(index)
					continue

		_check_player_collision(ghost)
		_update_ghost_sprite(ghost)

	queue_redraw()


func _check_player_collision(ghost: Dictionary) -> void:
	if (
		player == null
		or player.is_frozen()
		or int(ghost["phase"]) != Phase.FLYING
	):
		return

	var distance: float = player.global_position.distance_to(
		to_global(ghost["position"])
	)

	if distance <= 34.0:
		ghost["player_hit"] = true
		player.freeze_for(block_duration)
		ghost["phase"] = Phase.LEAVING


func spawn_ghost() -> bool:
	if objects == null or ghosts.size() >= max_ghosts:
		return false

	var from_left: bool = randf() < 0.5
	var edge_x: float = -70.0 if from_left else 1350.0
	var entry_position := Vector2(
		edge_x,
		randf_range(100.0, 230.0)
	)
	var ghost_type: int = ghosts.size() % 2

	# Створюємо графічного привида
	var sprite := _create_ghost_sprite(ghost_type)
	sprite.position = entry_position

	ghosts.append({
		"position": entry_position,
		"exit": Vector2(edge_x, 90.0),
		"phase": Phase.FLYING,
		"hunt_time_left": hunt_duration,
		"seed": randf_range(0.0, TAU),
		"player_hit": false,
		"ghost_type": ghost_type,
		"sprite": sprite
	})

	queue_redraw()
	return true


func _create_ghost_sprite(ghost_type: int) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.name = "AnimatedGhost"
	sprite.centered = true

	add_child(sprite)

	if ghost_animations.is_empty():
		push_warning("No ghost animations loaded")
		return sprite

	var animation_index: int = ghost_type
	animation_index = mini(
		animation_index,
		ghost_animations.size() - 1
	)
	sprite.sprite_frames = ghost_animations[animation_index]

	var texture: Texture2D = (
		sprite.sprite_frames.get_frame_texture("fly", 0)
	)

	if texture != null:
		var texture_size := texture.get_size()
		var longest_side := maxf(
			texture_size.x,
			texture_size.y
		)

		if longest_side > 0.0:
			sprite.scale = Vector2.ONE * (
				ghost_size / longest_side
			)

	sprite.play("fly")
	return sprite


func _update_ghost_sprite(ghost: Dictionary) -> void:
	var sprite := ghost.get("sprite") as AnimatedSprite2D

	if not is_instance_valid(sprite):
		return

	var position: Vector2 = ghost["position"]
	var seed_value: float = float(ghost["seed"])

	# Легке плавне погойдування під час польоту
	position.y += sin(
		animation_time * 3.5 + seed_value
	) * 7.0

	sprite.position = position


func _remove_ghost_sprite(ghost: Dictionary) -> void:
	var sprite := ghost.get("sprite") as AnimatedSprite2D

	if is_instance_valid(sprite):
		sprite.hide()
		sprite.queue_free()


func _draw() -> void:
	for ghost in ghosts:
		if int(ghost["phase"]) != Phase.FLYING:
			continue

		var position: Vector2 = ghost["position"]
		var seed_value: float = float(ghost["seed"])

		position.y += sin(
			animation_time * 3.5 + seed_value
		) * 7.0

		var remaining: float = float(ghost["hunt_time_left"])
		var progress: float = clampf(
			remaining / hunt_duration,
			0.0,
			1.0
		)

		draw_arc(
			position + Vector2(0, 8),
			37.0,
			-PI * 0.5,
			-PI * 0.5 + TAU * progress,
			36,
			Color(0.8, 0.65, 1.0, 0.9),
			3.0,
			true
		)
