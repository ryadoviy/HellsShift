extends Node

const MUSIC_PATH: String = "res://assets/audio/music/castle.ogg"

var music_player: AudioStreamPlayer


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

    _ensure_bus("Music")
    _ensure_bus("SFX")

    music_player = AudioStreamPlayer.new()
    music_player.name = "CastleMusic"
    music_player.bus = "Music"
    music_player.volume_db = -16.0
    add_child(music_player)

    var source := load(MUSIC_PATH) as AudioStreamOggVorbis

    if source == null:
        push_error("Cannot load castle.ogg")
        return

    var looping_music := source.duplicate() as AudioStreamOggVorbis
    looping_music.loop = true
    music_player.stream = looping_music
    music_player.play()


func _ensure_bus(bus_name: String) -> void:
    if AudioServer.get_bus_index(bus_name) >= 0:
        return

    AudioServer.add_bus()
    var index: int = AudioServer.bus_count - 1
    AudioServer.set_bus_name(index, bus_name)
    AudioServer.set_bus_send(index, "Master")


func _process(delta: float) -> void:
    if music_player == null:
        return

    var target_volume: float = -16.0
    var manager := get_tree().current_scene as GameManager

    if manager != null:
        match manager.state:
            GameManager.GameState.PLAYING:
                target_volume = -14.0
            GameManager.GameState.PAUSED:
                target_volume = -24.0
            GameManager.GameState.RESULT:
                target_volume = -20.0

    music_player.volume_db = move_toward(
        music_player.volume_db,
        target_volume,
        delta * 12.0
    )


func set_music_volume(value: float) -> void:
    var index: int = AudioServer.get_bus_index("Music")
    if index >= 0:
        AudioServer.set_bus_volume_linear(
            index, clampf(value, 0.0, 1.0)
        )


func set_sfx_volume(value: float) -> void:
    var index: int = AudioServer.get_bus_index("SFX")
    if index >= 0:
        AudioServer.set_bus_volume_linear(
            index, clampf(value, 0.0, 1.0)
        )
