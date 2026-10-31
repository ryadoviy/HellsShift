
extends Control

signal resume_pressed
signal restart_pressed
signal menu_pressed

@onready var dark_overlay: ColorRect = $DarkOverlay
@onready var center_container: CenterContainer = $CenterContainer

@onready var resume_button: Button = $CenterContainer/MenuPanel/Buttons/ResumeButton
@onready var restart_button: Button = $CenterContainer/MenuPanel/Buttons/RestartButton
@onready var menu_button: Button = $CenterContainer/MenuPanel/Buttons/MainMenuButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Розмір усього меню
	set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	position = Vector2.ZERO
	size = get_viewport_rect().size

	# Затемнення на весь екран
	dark_overlay.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	# Контейнер на весь екран
	center_container.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	# Кнопки
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
