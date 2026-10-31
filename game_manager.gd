
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
var fire_growth_time_left: float = 10.0
var correct_potion_streak: int = 0
var water_unlocked: bool = false

func _ready() -> void:
	if config == null:
		config = GameConfig.normal()
	else:
		config = config.duplicate(true) as GameConfig

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
	fire_growth_time_left -= delta

	while fire_growth_time_left <= 0.0:
		fire_growth_time_left += config.fire_growth_interval
		fire.increase(config.fire_growth_amount)

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

func apply_fire_difficulty() -> void:
	match selected_difficulty.to_upper():
		"EASY":
			config.fire_growth_interval = 15.0
			config.fire_growth_amount = 3.0
			config.potions_for_water = 3
			gameplay.ghost_system.configure(18.0, 2, 3.0, 5.0)

		"NORMAL":
			config.fire_growth_interval = 10.0
			config.fire_growth_amount = 5.0
			config.potions_for_water = 5
			gameplay.ghost_system.configure(15.0, 4, 5.0, 7.0)

		"HARD":
			config.fire_growth_interval = 7.0
			config.fire_growth_amount = 8.0
			config.potions_for_water = 7
			gameplay.ghost_system.configure(12.0, 6, 7.0, 9.0)

		_:
			config.fire_growth_interval = 10.0
			config.fire_growth_amount = 5.0
			config.potions_for_water = 5
			gameplay.ghost_system.configure(15.0, 4, 5.0, 7.0)

	print("DIFFICULTY: ", selected_difficulty)
	print("FIRE EVERY: ", config.fire_growth_interval, "s")
	print("FIRE GROWTH: +", config.fire_growth_amount, "%")


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_resume_pressed() -> void:
	_set_state(GameState.PLAYING)


func start_game() -> void:
	apply_fire_difficulty()
	score = 0
	potions_brewed = 0
	time_left = config.duration
	
	fire_growth_time_left = config.fire_growth_interval
	correct_potion_streak = 0
	water_unlocked = false
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
	print("POTION COMPLETED!")
	potions_brewed += 1
	correct_potion_streak += 1
	add_score(100)

	if (
		not water_unlocked
		and correct_potion_streak >= config.potions_for_water
	):
		water_unlocked = true

	fire.increase(config.success_fire)
	modifier_manager.on_potion_completed(self)


func on_ingredient_wrong() -> void:
	fire.increase(config.wrong_fire)


func use_water() -> bool:
	if state != GameState.PLAYING:
		return false

	fire.decrease(config.water_power)

	water_unlocked = false
	correct_potion_streak = 0

	_update_hud()
	return true

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

	var recipe_name: String = ""
	var ingredient_names: Array = []
	var recipe_progress: int = 0
	var held_item_name: String = ""

	if gameplay != null and gameplay.recipes != null:
		var recipes: RecipeManager = gameplay.recipes

		if not recipes.current_recipe.is_empty():
			recipe_name = str(
				recipes.current_recipe.get("name", "")
			)

			var ingredient_ids: Array = recipes.current_recipe.get(
				"ingredients", []
			)

			for item_id in ingredient_ids:
				ingredient_names.append(
					str(Gameplay.ITEM_NAMES.get(item_id, item_id))
				)

			recipe_progress = recipes.ingredient_index

	var current_player: CorePlayer = player as CorePlayer

	if current_player != null and current_player.inventory != null:
		var held_item: StringName = current_player.inventory.held_item

		if held_item != &"":
			held_item_name = str(
				Gameplay.ITEM_NAMES.get(held_item, held_item)
			)

	var hud_data: Dictionary = {
		"score": score,
		"time": time_left,
		"fire": fire.level,
		"recipe": recipe_name,
		"ingredients": ingredient_names,
		"progress": recipe_progress,
		"item": held_item_name
	}

	custom_hud.update_display(hud_data)
