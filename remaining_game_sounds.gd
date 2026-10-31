extends Node

const SOUND_FILES = {
	"ingredient": "ingredient",
	"complete": "potion_complete",
	"wrong": "wrong_ingredient",
	"water": "water",
	"ghost": "ghost",
	"fire": "fire"
}

const SOUND_VOLUMES = {
	"ingredient": -10.0,
	"complete": -12.0,
	"wrong": -14.0,
	"water": -10.0,
	"ghost": -16.0,
	"fire": -32.0
}

var players: Dictionary = {}
var connections: Array[Dictionary] = []
var bound_gameplay: Gameplay


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if AudioServer.get_bus_index("SFX") < 0:
		AudioServer.add_bus()
		var index: int = AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, "SFX")
		AudioServer.set_bus_send(index, "Master")
	
	for key in SOUND_FILES:
		var sound_id: String = str(key)
		var path: String = "res://assets/audio/sfx/%s.mp3" % SOUND_FILES[key]
		
		if not ResourceLoader.exists(path):
			push_warning("Missing sound: " + path)
			continue
		
		var source := load(path) as AudioStreamMP3
		if source == null:
			continue
		
		var stream := source.duplicate() as AudioStreamMP3
		stream.loop = sound_id == "fire"
		
		var audio := AudioStreamPlayer.new()
		audio.name = sound_id
		audio.bus = "SFX"
		audio.volume_db = float(SOUND_VOLUMES[key])
		audio.stream = stream
		add_child(audio)
		players[sound_id] = audio


func _process(delta: float) -> void:
	var manager := get_tree().current_scene as GameManager
	var current: Gameplay = null
	
	if manager != null:
		current = manager.gameplay
	
	_bind_gameplay(current)
	
	if manager == null:
		_stop_all()
		return
	
	if manager.state == GameManager.GameState.PAUSED:
		_set_paused(true)
		return
	
	_set_paused(false)
	
	if manager.state != GameManager.GameState.PLAYING:
		_stop_all()
		return
	
	_update_fire(manager, delta)


func _bind_gameplay(current: Gameplay) -> void:
	if is_instance_valid(bound_gameplay):
		if bound_gameplay == current:
			return
	elif current == null:
		return
	
	_disconnect_signals()
	bound_gameplay = current
	
	if not is_instance_valid(bound_gameplay):
		return
	
	_connect_event(bound_gameplay, &"water_used", _play.bind("water"))
	
	var recipes: RecipeManager = bound_gameplay.recipes
	if is_instance_valid(recipes):
		_connect_event(recipes, &"ingredient_correct", _play.bind("ingredient"))
		_connect_event(recipes, &"ingredient_wrong", _on_wrong)
		_connect_event(recipes, &"recipe_completed", _play.bind("complete"))
	
	var ghosts: GhostSabotage = bound_gameplay.ghost_system
	if is_instance_valid(ghosts):
		_connect_event(ghosts, &"ghost_spawned", _play.bind("ghost"))


func _connect_event(source: Node, event: StringName, callback: Callable) -> void:
	if not source.has_signal(event):
		push_warning("Missing audio event: " + str(event))
		return
	
	if not source.is_connected(event, callback):
		source.connect(event, callback)
		connections.append({
			"source": source,
			"event": event,
			"callback": callback
		})


func _disconnect_signals() -> void:
	for connection in connections:
		var source: Object = connection["source"]
		var event: StringName = connection["event"]
		var callback: Callable = connection["callback"]
		
		if is_instance_valid(source):
			if source.is_connected(event, callback):
				source.disconnect(event, callback)
	
	connections.clear()
	bound_gameplay = null


func _play(sound_id: String) -> void:
	var manager := get_tree().current_scene as GameManager
	if manager == null:
		return
	if manager.state != GameManager.GameState.PLAYING:
		return
	
	var audio := players.get(sound_id) as AudioStreamPlayer
	if audio == null:
		return
	
	audio.stream_paused = false
	audio.play()


func _on_wrong() -> void:
	_play("ingredient")
	_play("wrong")


func _update_fire(manager: GameManager, delta: float) -> void:
	var audio := players.get("fire") as AudioStreamPlayer
	if audio == null:
		return
	
	if not is_instance_valid(manager.fire):
		audio.stop()
		return
	
	var intensity: float = clampf(manager.fire.level / 100.0, 0.0, 1.0)
	
	if intensity <= 0.0:
		audio.stop()
		audio.volume_db = -40.0
		return
	
	var target_volume: float = lerpf(-32.0, -12.0, intensity)
	audio.volume_db = move_toward(audio.volume_db, target_volume, delta * 15.0)
	
	if not audio.playing:
		audio.play()


func _set_paused(paused: bool) -> void:
	for value in players.values():
		var audio := value as AudioStreamPlayer
		audio.stream_paused = paused


func _stop_all() -> void:
	for value in players.values():
		var audio := value as AudioStreamPlayer
		audio.stop()
		audio.stream_paused = false
	
	var fire_audio := players.get("fire") as AudioStreamPlayer
	if fire_audio != null:
		fire_audio.volume_db = -40.0
