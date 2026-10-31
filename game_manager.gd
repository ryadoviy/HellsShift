
extends Node2D
class_name GameManager

enum GameState { MENU, PLAYING, PAUSED, RESULT }

@export var config: GameConfig

@onready var fire: FireSystem = $Fire
@onready var modifier_manager: ModifierManager = $ModifierManager
@onready var player: CharacterBody2D = $Player

@onready var main_menu = $MainMenu
@onready var custom_hud = $CustomHUD
@onready var pause_menu = $PauseMenu
@onready var game_over = $GameOver

var score: int = 0
var potions_brewed: int = 0
var time_left: float = 0.0
var state: GameState = GameState.MENU
var result_text: String = ""
var gameplay: Gameplay

var selected_difficulty: String = "NORMAL"


func _ready() -> void:
	if config == null:
		config = GameConfig.normal()

	gameplay = Gameplay.new()
	gameplay.name = "Gameplay"
	add_child(gameplay)
	gameplay.setup(self)

	fire.fire_maxed.connect(_on_fire_maxed)

	main_menu.play_pressed.connect(_on_play_pressed)
	main_menu.exit_pressed.connect(_on_exit_pressed)

	pause_menu.resume_pressed.connect(_on_resume_pressed)
	pause_menu.restart_pressed.connect(reset_game)
	pause_menu.menu_pressed.connect(return_to_menu)

	game_over.play_again_pressed.connect(reset_game)
	game_over.menu_pressed.connect(return_to_menu)

	# Приховуємо старий інтерфейс
	var old_hud = get_node_or_null("HUD")
	if old_hud != null:
		old_hud.hide()

	var old_overlay = get_node_or_null(
        "ScreenOverlay/Overlay"
	)
	if old_overlay != null:
		old_overlay.hide()

	time_left = config.duration
	_set_state(GameState.MENU)


func _process(delta: float) -> void:
	if state != GameState.PLAYING:
		return

	time_left = maxf(0.0, time_left - delta)

	modifier_manager.update_modifier(self, delta)
	_update_hud()

	if time_left <= 0.0:
		end_game(false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		if state == GameState.PLAYING:
			_set_state(GameState.PAUSED)
		elif state == GameState.PAUSED:
			_set_state(GameState.PLAYING)


func _on_play_pressed(difficulty: String) -> void:
	selected_difficulty = difficulty
	start_game()


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_resume_pressed() -> void:
	_set_state(GameState.PLAYING)


func start_game() -> void:
	score = 0
	potions_brewed = 0
	time_left = config.duration
	result_text = ""

	fire.set_level(config.initial_fire)
	gameplay.reset_round()

	player.position = Vector2(640, 560)

	_set_state(GameState.PLAYING)
	modifier_manager.on_game_started(self)


func reset_game() -> void:
	start_game()


func return_to_menu() -> void:
	_set_state(GameState.MENU)


func end_game(burned: bool) -> void:
	if state == GameState.RESULT:
		return

	result_text = (
        "LABORATORY BURNED!"
		if burned else "YOU SURVIVED!"
	)

	_set_state(GameState.RESULT)

	game_over.show_results(
		score,
		potions_brewed,
		burned
	)


func _on_fire_maxed() -> void:
	if state == GameState.PLAYING:
		end_game(true)


func add_score(amount: int) -> void:
	score += amount
	_update_hud()


func on_recipe_completed() -> void:
	potions_brewed += 1
	add_score(100)

	fire.increase(config.success_fire)
	modifier_manager.on_potion_completed(self)


func on_ingredient_wrong() -> void:
	fire.increase(config.wrong_fire)


func use_water() -> void:
	fire.decrease(config.water_power)


func _set_state(new_state: GameState) -> void:
	state = new_state

	var is_playing: bool = (
		state == GameState.PLAYING
	)

	player.set_physics_process(is_playing)
	player.set_process_unhandled_input(is_playing)

	main_menu.visible = (
		state == GameState.MENU
	)

	custom_hud.visible = (
		state == GameState.PLAYING
		or state == GameState.PAUSED
	)

	pause_menu.visible = (
		state == GameState.PAUSED
	)

	game_over.visible = (
		state == GameState.RESULT
	)

	_update_hud()


func _update_hud() -> void:
	if not is_node_ready():
		return

	var hud_data: Dictionary = {
		"score": score,
		"time": time_left,
		"fire": fire.level,
		"recipe": "",
		"ingredients": [],
		"progress": 0,
		"item": ""
	}

	custom_hud.update_display(hud_data)
