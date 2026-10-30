
extends Control

signal resume_pressed
signal restart_pressed
signal menu_pressed

@onready var resume_button: Button = $CenterContainer/MenuPanel/Buttons/ResumeButton
@onready var restart_button: Button = $CenterContainer/MenuPanel/Buttons/RestartButton
@onready var menu_button: Button = $CenterContainer/MenuPanel/Buttons/MainMenuButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	resume_button.pressed.connect(
		func(): resume_pressed.emit()
	)

	restart_button.pressed.connect(
		func(): restart_pressed.emit()
	)

	menu_button.pressed.connect(
		func(): menu_pressed.emit()
	)


func show_pause() -> void:
	show()


func hide_pause() -> void:
	hide()
