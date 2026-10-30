# HellsShift — Core / Fire / Secret Conditions

Стартовий каркас Godot 4 для розробника №3.

## Запуск

1. Відкрити папку в Godot 4.
2. Запустити `main.tscn` або натиснути F6.
3. Натиснути `E`, щоб почати гру.

## Керування

- `WASD` — рух (підготовлено в Input Map)
- `E` — старт / взаємодія
- `Q` — скидання предмета (зарезервовано)
- `Esc` — пауза

## Інтеграційні точки

- `FireSystem`: `increase`, `decrease`, `set_level`, `fire_maxed`
- `GameManager`: `start_game`, `end_game`, `add_score`, `use_water`
- `ModifierManager`: методи реакції на події вже створені
- `Laboratory`: сигнал `location_changed`

Сцена навмисно не містить логіки інших розробників. Готові `Player`, `RecipeManager`, HUD та предмети можна замінити їхніми сценами, зберігши імена вузлів і погоджені сигнали.
