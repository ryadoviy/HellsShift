
extends Control

signal play_again_pressed
signal menu_pressed

@onready var result_title: Label = $CenterContainer/ResultPanel/Content/ResultTitle
@onready var score_label: Label = $CenterContainer/ResultPanel/Content/ScoreLabel
@onready var potions_label: Label = $CenterContainer/ResultPanel/Content/PotionsLabel

@onready var play_again_button: Button = $CenterContainer/ResultPanel/Content/PlayAgainButton
@onready var menu_button: Button = $CenterContainer/ResultPanel/Content/MainMenuButton


func _ready() -> void:
	play_again_button.pressed.connect(_on_play_again)
	menu_button.pressed.connect(_on_main_menu)


func show_results(
	score: int,
	potions: int,
	burned: bool
) -> void:

	if burned:
		result_title.text = "LABORATORY BURNED!"
	else:
		result_title.text = "YOU SURVIVED!"

	score_label.text = "SCORE: %d" % score
	potions_label.text = "POTIONS BREWED: %d" % potions

	show()


func _on_play_again() -> void:
	play_again_pressed.emit()


func _on_main_menu() -> void:
	menu_pressed.emit()
