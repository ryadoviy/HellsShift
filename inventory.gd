extends Node
class_name PlayerInventory

signal item_changed(item_id: StringName)

var held_item: StringName = &""


# Чи є предмет у руках?
func has_item() -> bool:
	return held_item != &""


# Взяти предмет. Якщо руки зайняті — повернути false.
func take_item(item_id: StringName) -> bool:
	if has_item() or item_id == &"":
		return false

	held_item = item_id
	item_changed.emit(held_item)
	return true


# Забрати предмет із рук і повернути його назву.
func remove_item() -> StringName:
	var removed_item := held_item
	held_item = &""
	item_changed.emit(held_item)
	return removed_item


# Очистити інвентар під час нового запуску гри.
func reset() -> void:
	held_item = &""
	item_changed.emit(held_item)