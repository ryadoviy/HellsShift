extends Node2D
class_name GameManager

enum GameState { MENU, PLAYING, PAUSED, RESULT }

@export var config: GameConfig

@onready var fire: FireSystem = $Fire
@onready var modifier_manager: ModifierManager = $ModifierManager
@onready var player: CharacterBody2D = $Player
@onready var overlay: Panel = $ScreenOverlay/Overlay
@onready var status_label: Label = $HUD/Status
@onready var score_label: Label = $HUD/Score
@onready var time_label: Label = $HUD/Time
@onready var fire_label: Label = $HUD/Fire

var score := 0
var time_left := 0.0
var state := GameState.MENU
var result_text := ""
var gameplay: Gameplay


func _ready() -> void:
	if config == null:
		config = GameConfig.normal()

	fire.fire_maxed.connect(_on_fire_maxed)
	time_left = config.duration

	# Текст меню відображається поверх затемнення.
	$HUD.layer = 2
	$ScreenOverlay.layer = 1

	gameplay = Gameplay.new()
	add_child(gameplay)
	gameplay.setup(self)

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
	if event.is_echo():
		return

	if event.is_action_pressed("pause_game"):
		if state == GameState.PLAYING:
			_set_state(GameState.PAUSED)
		elif state == GameState.PAUSED:
			_set_state(GameState.PLAYING)

	elif event.is_action_pressed("interact"):
		if state == GameState.MENU or state == GameState.RESULT:
			start_game()


func start_game() -> void:
	score = 0
	time_left = config.duration
	result_text = ""

	player.position = Vector2(640, 560)
	gameplay.reset_round()

	_set_state(GameState.PLAYING)
	fire.set_level(config.initial_fire)

	if state == GameState.PLAYING:
		modifier_manager.on_game_started(self)


func reset_game() -> void:
	start_game()


func end_game(burned: bool) -> void:
	if state == GameState.RESULT:
		return

	result_text = (
		"GAME OVER - THE LABORATORY BURNED"
		if burned
		else "YOU SURVIVED"
	)

	_set_state(GameState.RESULT)


func _on_fire_maxed() -> void:
	end_game(true)


func add_score(amount: int) -> void:
	score += amount
	_update_hud()


func on_recipe_completed() -> void:
	if state != GameState.PLAYING:
		return

	add_score(100)
	fire.increase(config.success_fire)
	modifier_manager.on_potion_completed(self)


func on_ingredient_wrong() -> void:
	if state != GameState.PLAYING:
		return

	fire.increase(config.wrong_fire)


func use_water() -> void:
	if state != GameState.PLAYING:
		return

	fire.decrease(config.water_power)


func _set_state(new_state: GameState) -> void:
	state = new_state

	player.set_process_unhandled_input(state == GameState.PLAYING)
	player.set_physics_process(state == GameState.PLAYING)
	player.velocity = Vector2.ZERO

	overlay.visible = state != GameState.PLAYING

	match state:
		GameState.MENU:
			status_label.text = "HELL'S SHIFT\nPress E to start"

		GameState.PAUSED:
			status_label.text = "PAUSED\nPress ESC to resume"

		GameState.RESULT:
			status_label.text = "%s\nSCORE: %d | POTIONS: %d\nPress E to restart" % [
				result_text,
				score,
				gameplay.recipes.completed_count
			]

		GameState.PLAYING:
			status_label.text = ""

	_update_hud()


func _update_hud() -> void:
	score_label.text = "SCORE: %d" % score
	time_label.text = "TIME: %03d" % ceili(time_left)
	fire_label.text = "FIRE: %d%%" % ceili(fire.level)