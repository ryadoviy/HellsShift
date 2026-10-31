
extends Control

signal play_again_pressed
signal menu_pressed

@onready var center_container: CenterContainer = $CenterContainer
@onready var result_title: Label = $CenterContainer/ResultPanel/Content/ResultTitle
@onready var score_label: Label = $CenterContainer/ResultPanel/Content/ScoreLabel
@onready var potions_label: Label = $CenterContainer/ResultPanel/Content/PotionsLabel
@onready var play_again_button: Button = $CenterContainer/ResultPanel/Content/PlayAgainButton
@onready var menu_button: Button = $CenterContainer/ResultPanel/Content/MainMenuButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	position = Vector2.ZERO
	size = get_viewport_rect().size

	center_container.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	play_again_button.pressed.connect(
		func(): play_again_pressed.emit()
	)

	menu_button.pressed.connect(
		func(): menu_pressed.emit()
	)


func show_results(score: int, potions: int, burned: bool) -> void:
	result_title.text = (
        "LABORATORY BURNED!"
		if burned else "YOU SURVIVED!"
	)

	score_label.text = "SCORE: %d" % score
	potions_label.text = "POTIONS BREWED: %d" % potions

	show()
