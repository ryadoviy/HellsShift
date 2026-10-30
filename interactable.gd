extends Node2D
class_name GameInteractable

signal interacted(target: GameInteractable, actor: Node)

enum Kind { INGREDIENT, WATER, CAULDRON }

@export var kind: Kind = Kind.INGREDIENT
@export var item_id: StringName = &"mushroom"
@export var display_name: String = "Mushroom"
@export var object_color: Color = Color(0.7, 0.3, 0.8)
@export var interaction_distance: float = 70.0


func _ready() -> void:
	add_to_group("interactables")

	var caption := Label.new()
	caption.text = display_name
	caption.position = Vector2(-65, 28)
	caption.size = Vector2(130, 30)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(caption)

	queue_redraw()


# Гравець може взаємодіяти лише поблизу об'єкта.
func can_interact(actor: Node2D) -> bool:
	return global_position.distance_to(actor.global_position) <= interaction_distance


func interact(actor: Node2D) -> void:
	if can_interact(actor):
		interacted.emit(self, actor)


# Тимчасове зображення для перевірки механіки.
func _draw() -> void:
	var radius: float = 35.0 if kind == Kind.CAULDRON else 20.0
	draw_circle(Vector2.ZERO, radius, object_color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color.WHITE, 2.0)