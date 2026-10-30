
extends Control

signal play_pressed(difficulty: String)
signal exit_pressed

@onready var play_button: Button = $MenuButtons/PlayButton
@onready var difficulty_button: Button = $MenuButtons/DifficultyButton
@onready var how_button: Button = $MenuButtons/HowToPlayButton
@onready var exit_button: Button = $MenuButtons/ExitButton
@onready var instructions: PanelContainer = $HowToPlayPanel
@onready var dark_overlay: ColorRect = $DarkOverlay
var difficulties: Array[String] = [
	"EASY", "NORMAL", "HARD"
]

var difficulty_index: int = 1


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	difficulty_button.pressed.connect(_change_difficulty)
	how_button.pressed.connect(_toggle_instructions)
	exit_button.pressed.connect(_on_exit_pressed)
	dark_overlay.hide()
	dark_overlay.gui_input.connect(_on_overlay_input)

	instructions.hide()
	_update_difficulty_text()


func _on_play_pressed() -> void:
	play_pressed.emit(difficulties[difficulty_index])


func _change_difficulty() -> void:
	difficulty_index = (
		difficulty_index + 1
	) % difficulties.size()

	_update_difficulty_text()


func _update_difficulty_text() -> void:
	difficulty_button.text = (
		"DIFFICULTY: " +
		difficulties[difficulty_index]
	)


func _toggle_instructions() -> void:
	var is_open = not instructions.visible

	instructions.visible = is_open
	dark_overlay.visible = is_open



func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and not event.echo:
			if event.keycode == KEY_H:
				instructions.hide()
				dark_overlay.hide()


func _on_exit_pressed() -> void:
	exit_pressed.emit()
	

func _on_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				instructions.hide()
				dark_overlay.hide()
				dark_overlay.accept_event()
