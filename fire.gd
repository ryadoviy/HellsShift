
extends Node2D
class_name FireSystem

signal fire_changed(value: float)
signal fire_maxed

@export var level: float = 20.0

# Розміри стікера вогню
@export var min_fire_size: float = 200.0
@export var max_fire_size: float = 500.0

# Старий вогонь і освітлення
@onready var flame: Polygon2D = $Flame
@onready var light: PointLight2D = $PointLight2D

# Новий стікер
@onready var fire_sprite: Sprite2D = $FireSprite

var _has_emitted_max := false


func _ready() -> void:
	# Приховуємо стару помаранчеву фігуру
	flame.hide()

	# Встановлюємо початковий рівень пожежі
	set_level(level)


func increase(amount: float) -> void:
	set_level(level + amount)


func decrease(amount: float) -> void:
	set_level(level - amount)


func set_level(value: float) -> void:
	level = clampf(value, 0.0, 100.0)

	# Оновлюємо розмір стікера
	update_fire_visual()

	# Змінюємо силу світіння
	light.energy = 0.35 + level / 100.0

	# Повідомляємо HUD про рівень пожежі
	fire_changed.emit(level)

	# Якщо пожежа досягла 100% — Game Over
	if level >= 100.0 and not _has_emitted_max:
		_has_emitted_max = true
		fire_maxed.emit()
	elif level < 100.0:
		_has_emitted_max = false


func update_fire_visual() -> void:
	if fire_sprite.texture == null:
		return

	# Рівень пожежі від 0.0 до 1.0
	var progress: float = level / 100.0

	# Плавно змінюємо бажаний розмір
	var current_size: float = lerpf(
		min_fire_size,
		max_fire_size,
		progress
	)

	# Отримуємо розмір оригінального PNG
	var texture_size: Vector2 = fire_sprite.texture.get_size()

	var longest_side: float = maxf(
		texture_size.x,
		texture_size.y
	)

	if longest_side <= 0.0:
		return

	# Підбираємо масштаб під бажаний розмір
	var scale_factor: float = current_size / longest_side

	fire_sprite.scale = Vector2(
		scale_factor,
		scale_factor
	)
