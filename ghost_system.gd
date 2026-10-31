extends Node2D
class_name GhostSabotage

signal ghost_spawned

enum Phase { FLYING, BLOCKING, LEAVING }

# Учасник №3 може змінювати ці параметри через configure().
var spawn_interval: float = 25.0
var max_ghosts: int = 2
var block_duration: float = 3.0
var flight_speed: float = 180.0

var objects: Node2D
var ghosts: Array[Dictionary] = []
var spawn_time_left: float = 8.0
var animation_time: float = 0.0


func setup(gameplay_objects: Node2D) -> void:
	objects = gameplay_objects
	z_index = 6


func configure(
	interval: float,
	limit: int,
	duration: float
) -> void:
	spawn_interval = maxf(1.0, interval)
	max_ghosts = clampi(limit, 0, 3)
	block_duration = maxf(0.1, duration)


func reset() -> void:
	for ghost in ghosts:
		_release_target(ghost)

	ghosts.clear()
	spawn_time_left = minf(8.0, spawn_interval)
	animation_time = 0.0
	queue_redraw()


# Викликається Gameplay лише під час активної гри.
func advance(delta: float) -> void:
	if objects == null:
		return

	animation_time += delta
	spawn_time_left -= delta

	if spawn_time_left <= 0.0:
		spawn_time_left = spawn_interval
		spawn_ghost()

	for index in range(ghosts.size() - 1, -1, -1):
		var ghost: Dictionary = ghosts[index]
		var target := ghost["target"] as GameInteractable
		var position: Vector2 = ghost["position"]
		var phase: int = int(ghost["phase"])

		if not is_instance_valid(target):
			_release_target(ghost)
			ghosts.remove_at(index)
			continue

		match phase:
			Phase.FLYING:
				var destination: Vector2 = to_local(
					target.global_position
				) + Vector2(0, -25)

				position = position.move_toward(
					destination,
					flight_speed * delta
				)
				ghost["position"] = position

				if position.distance_to(destination) < 2.0:
					ghost["phase"] = Phase.BLOCKING
					ghost["time_left"] = block_duration
					target.set_meta("ghost_blocked", true)
					target.modulate = Color(0.6, 0.7, 1.0)

			Phase.BLOCKING:
				ghost["position"] = to_local(
					target.global_position
				) + Vector2(0, -25)

				ghost["time_left"] = maxf(
					0.0,
					float(ghost["time_left"]) - delta
				)

				if float(ghost["time_left"]) <= 0.0:
					_release_target(ghost)
					ghost["phase"] = Phase.LEAVING

			Phase.LEAVING:
				var exit_position: Vector2 = ghost["exit"]
				position = position.move_toward(
					exit_position,
					flight_speed * delta
				)
				ghost["position"] = position

				if position.distance_to(exit_position) < 2.0:
					ghosts.remove_at(index)

	queue_redraw()


# Публічний метод також підходить для проклятих подій.
func spawn_ghost() -> bool:
	if objects == null or ghosts.size() >= max_ghosts:
		return false

	var candidates: Array[GameInteractable] = []

	for child in objects.get_children():
		var target := child as GameInteractable

		if target == null or not target.is_visible_in_tree():
			continue

		if target.kind != GameInteractable.Kind.INGREDIENT:
			continue

		if target.get_meta("dropped", false):
			continue

		if target.get_meta("ghost_reserved", false):
			continue

		candidates.append(target)

	if candidates.is_empty():
		return false

	var target: GameInteractable = candidates.pick_random()
	target.set_meta("ghost_reserved", true)

	var from_left: bool = randf() < 0.5
	var edge_x: float = -70.0 if from_left else 1350.0
	var entry_position := Vector2(edge_x, randf_range(100.0, 230.0))

	ghosts.append({
		"target": target,
		"position": entry_position,
		"exit": Vector2(edge_x, 90.0),
		"phase": Phase.FLYING,
		"time_left": block_duration,
		"seed": randf_range(0.0, TAU),
		"original_modulate": target.modulate,
		"released": false
	})

	queue_redraw()
	ghost_spawned.emit()
	return true


func _release_target(ghost: Dictionary) -> void:
	if bool(ghost.get("released", false)):
		return

	ghost["released"] = true

	var target := ghost.get("target") as GameInteractable

	if not is_instance_valid(target):
		return

	target.set_meta("ghost_blocked", false)
	target.set_meta("ghost_reserved", false)
	target.modulate = ghost["original_modulate"]


func _draw() -> void:
	for ghost in ghosts:
		var position: Vector2 = ghost["position"]
		var seed_value: float = float(ghost["seed"])

		position.y += sin(
			animation_time * 3.5 + seed_value
		) * 7.0

		_draw_ghost(position, seed_value)

		if int(ghost["phase"]) == Phase.BLOCKING:
			var remaining: float = float(ghost["time_left"])
			var progress: float = clampf(
				remaining / block_duration,
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


func _draw_ghost(position: Vector2, seed_value: float) -> void:
	# М'яке світіння.
	for ring in range(4):
		draw_circle(
			position,
			38.0 - float(ring) * 5.0,
			Color(0.65, 0.8, 1.0, 0.035)
		)

	var silhouette := PackedVector2Array()

	# Округла голова.
	for step in range(17):
		var angle: float = PI + PI * float(step) / 16.0
		silhouette.append(
			position + Vector2(
				cos(angle) * 25.0,
				sin(angle) * 28.0
			)
		)

	# Хвилястий нижній край.
	for step in range(9):
		var x: float = 25.0 - float(step) * 6.25
		var wave: float = sin(
			float(step) * PI * 0.5
			+ animation_time * 4.0
			+ seed_value
		) * 4.0

		silhouette.append(
			position + Vector2(x, 30.0 + wave)
		)

	draw_colored_polygon(
		silhouette,
		Color(0.78, 0.88, 1.0, 0.8)
	)

	draw_circle(
		position + Vector2(-9, -3),
		4.0,
		Color(0.16, 0.1, 0.3)
	)
	draw_circle(
		position + Vector2(9, -3),
		4.0,
		Color(0.16, 0.1, 0.3)
	)
	draw_circle(
		position + Vector2(0, 10),
		5.0,
		Color(0.22, 0.12, 0.35, 0.8)
	)