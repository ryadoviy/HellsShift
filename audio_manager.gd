extends Node

const MUSIC_PATH := "res://assets/audio/music/castle.ogg"
const CAULDRON_PATH := "res://assets/audio/sfx/cauldron.mp3"
const PICKUP_PATH := "res://assets/audio/sfx/pickup.mp3"

var music_player: AudioStreamPlayer
var cauldron_player: AudioStreamPlayer
var pickup_player: AudioStreamPlayer
var bound_inventory: PlayerInventory


func _ready() -> void:
	var remaining_sounds: Node = load("res://remaining_game_sounds.gd").new()
	remaining_sounds.name = "RemainingGameSounds"
	add_child(remaining_sounds)
	process_mode = Node.PROCESS_MODE_ALWAYS

	_ensure_bus("Music")
	_ensure_bus("SFX")

	music_player = _create_player("CastleMusic", "Music", -16.0)
	cauldron_player = _create_player("CauldronBubbling", "SFX", -10.0)
	pickup_player = _create_player("ItemPickup", "SFX", -12.0)

	var music_source := load(MUSIC_PATH) as AudioStreamOggVorbis
	if music_source != null:
		var music := music_source.duplicate() as AudioStreamOggVorbis
		music.loop = true
		music_player.stream = music
		music_player.play()

	var cauldron_source := load(CAULDRON_PATH) as AudioStreamMP3
	if cauldron_source != null:
		var bubbling := cauldron_source.duplicate() as AudioStreamMP3
		bubbling.loop = true
		cauldron_player.stream = bubbling

	var pickup_source := load(PICKUP_PATH) as AudioStreamMP3
	if pickup_source != null:
		var pickup := pickup_source.duplicate() as AudioStreamMP3
		pickup.loop = false
		pickup_player.stream = pickup


func _create_player(
	player_name: String,
	bus_name: String,
	volume: float
) -> AudioStreamPlayer:
	var audio := AudioStreamPlayer.new()
	audio.name = player_name
	audio.bus = bus_name
	audio.volume_db = volume
	add_child(audio)
	return audio


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return

	AudioServer.add_bus()
	var index: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "Master")


func _process(delta: float) -> void:
	var manager := get_tree().current_scene as GameManager
	var target_volume: float = -16.0

	if manager != null:
		match manager.state:
			GameManager.GameState.PLAYING:
				target_volume = -24.0
			GameManager.GameState.PAUSED:
				target_volume = -24.0
			GameManager.GameState.RESULT:
				target_volume = -20.0

	if music_player != null:
		music_player.volume_db = move_toward(
			music_player.volume_db,
			target_volume,
			delta * 12.0
		)

	_bind_inventory(manager)
	_update_cauldron_audio(manager)

	if pickup_player != null:
		if manager == null:
			pickup_player.stop()
		elif manager.state == GameManager.GameState.PAUSED:
			pickup_player.stream_paused = true
		elif manager.state == GameManager.GameState.PLAYING:
			pickup_player.stream_paused = false
		else:
			pickup_player.stop()
			pickup_player.stream_paused = false


func _bind_inventory(manager: GameManager) -> void:
	var current_inventory: PlayerInventory = null

	if manager != null:
		var current_player := manager.get_node_or_null("Player") as CorePlayer
		if current_player != null:
			current_inventory = current_player.inventory

	if is_instance_valid(bound_inventory):
		if bound_inventory == current_inventory:
			return

		if bound_inventory.item_changed.is_connected(_on_item_changed):
			bound_inventory.item_changed.disconnect(_on_item_changed)

	bound_inventory = current_inventory

	if is_instance_valid(bound_inventory):
		if not bound_inventory.item_changed.is_connected(_on_item_changed):
			bound_inventory.item_changed.connect(_on_item_changed)


func _on_item_changed(item_id: StringName) -> void:
	if item_id == &"":
		return

	var manager := get_tree().current_scene as GameManager
	if manager == null:
		return
	if manager.state != GameManager.GameState.PLAYING:
		return
	if pickup_player == null or pickup_player.stream == null:
		return

	pickup_player.stream_paused = false
	pickup_player.play()


func _update_cauldron_audio(manager: GameManager) -> void:
	if cauldron_player == null or cauldron_player.stream == null:
		return

	if manager == null:
		_stop_cauldron()
		return

	if manager.state == GameManager.GameState.PAUSED:
		cauldron_player.stream_paused = true
		return

	if manager.state != GameManager.GameState.PLAYING:
		_stop_cauldron()
		return

	if manager.gameplay == null:
		_stop_cauldron()
		return

	var recipes: RecipeManager = manager.gameplay.recipes
	if recipes == null or not recipes.is_brewing:
		_stop_cauldron()
		return

	cauldron_player.stream_paused = false
	if not cauldron_player.playing:
		cauldron_player.play()


func _stop_cauldron() -> void:
	cauldron_player.stop()
	cauldron_player.stream_paused = false


func set_music_volume(value: float) -> void:
	var index: int = AudioServer.get_bus_index("Music")
	if index >= 0:
		AudioServer.set_bus_volume_linear(index, clampf(value, 0.0, 1.0))


func set_sfx_volume(value: float) -> void:
	var index: int = AudioServer.get_bus_index("SFX")
	if index >= 0:
		AudioServer.set_bus_volume_linear(index, clampf(value, 0.0, 1.0))

# Кроки звучать лише під час фактичного переміщення.
var footsteps_player: AudioStreamPlayer
var footsteps_actor: CorePlayer
var footsteps_previous_position := Vector2.ZERO


func _physics_process(_delta: float) -> void:
	if footsteps_player == null:
		footsteps_player = AudioStreamPlayer.new()
		footsteps_player.name = "WitchFootsteps"
		footsteps_player.bus = "SFX"
		footsteps_player.volume_db = -16.0
		add_child(footsteps_player)

		var source := load(
            "res://assets/audio/sfx/footsteps.mp3"
		) as AudioStreamMP3

		if source != null:
			var steps := source.duplicate() as AudioStreamMP3
			steps.loop = true
			footsteps_player.stream = steps

	if footsteps_player.stream == null:
		return

	var manager := get_tree().current_scene as GameManager

	if manager == null:
		footsteps_player.stop()
		footsteps_actor = null
		return

	var actor := manager.get_node_or_null("Player") as CorePlayer

	if actor == null:
		footsteps_player.stop()
		footsteps_actor = null
		return

	if not is_instance_valid(footsteps_actor) or footsteps_actor != actor:
		footsteps_actor = actor
		footsteps_previous_position = actor.global_position
		footsteps_player.stop()
		return

	var distance: float = actor.global_position.distance_to(
		footsteps_previous_position
	)
	footsteps_previous_position = actor.global_position

	if manager.state == GameManager.GameState.PAUSED:
		footsteps_player.stream_paused = true
		return

	if manager.state != GameManager.GameState.PLAYING:
		footsteps_player.stop()
		footsteps_player.stream_paused = false
		return

	footsteps_player.stream_paused = false

	var walking: bool = (
		distance > 0.1
		and distance < 20.0
		and actor.velocity.length_squared() > 1.0
	)

	if walking:
		if not footsteps_player.playing:
			footsteps_player.play()
	else:
		footsteps_player.stop()
