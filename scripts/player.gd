extends CharacterBody2D
## Игрок-курьер. Все «ручки» механики — вот эти @export-переменные.
## Выбери узел Player в редакторе: числа появятся справа в Инспекторе, их можно крутить без кода.

## Скорость бега, пикселей в секунду. Больше число — быстрее бежит.
@export var speed: float = 300.0

## Сила прыжка, пикселей в секунду. Число отрицательное: в Godot ось Y смотрит ВНИЗ,
## поэтому прыжок вверх — это «минус». Чем меньше число (например -800), тем выше прыжок.
@export var jump_velocity: float = -600.0

## Гравитация — насколько сильно тянет вниз. Больше число — быстрее падает, прыжок короче.
@export var gravity: float = 1600.0

## Максимальная скорость падения, чтобы игрок не разгонялся бесконечно.
@export var max_fall_speed: float = 1200.0

## «Койот-тайм» (необязательно): сколько секунд после схода с края ещё можно прыгнуть.
## Прощает ошибку в доли секунды. 0 — выключено.
@export var coyote_time: float = 0.1

## «Буфер прыжка» (необязательно): сколько секунд игра помнит нажатие пробела,
## сделанное чуть ДО приземления, и прыгает сама при касании земли. 0 — выключено.
@export var jump_buffer_time: float = 0.1

## Когда false, игрок не слушается клавиш (после победы).
var controls_enabled := true

var _coyote_left := 0.0
var _buffer_left := 0.0


func _physics_process(delta: float) -> void:
	# 1. Гравитация: пока не стоим на земле, скорость вниз растёт.
	if not is_on_floor():
		velocity.y = min(velocity.y + gravity * delta, max_fall_speed)

	# 2. Таймеры койот-тайма и буфера прыжка.
	if is_on_floor():
		_coyote_left = coyote_time
	else:
		_coyote_left = max(_coyote_left - delta, 0.0)
	if controls_enabled and Input.is_action_just_pressed("jump"):
		_buffer_left = jump_buffer_time
	else:
		_buffer_left = max(_buffer_left - delta, 0.0)

	# 3. Прыжок: нажали (или нажимали недавно) и стоим на земле (или стояли недавно).
	# Управление выключено (победа) — буферный прыжок тоже не срабатывает.
	var wants_jump := controls_enabled and (_buffer_left > 0.0 or Input.is_action_just_pressed("jump"))
	var can_jump := is_on_floor() or _coyote_left > 0.0
	if wants_jump and can_jump:
		velocity.y = jump_velocity
		_coyote_left = 0.0
		_buffer_left = 0.0

	# 4. Бег влево-вправо: -1 (влево), 0 (стоим), +1 (вправо).
	var direction := Input.get_axis("move_left", "move_right") if controls_enabled else 0.0
	velocity.x = direction * speed

	move_and_slide()


## Вернуть игрока в точку старта (вызывается при рестарте).
func reset_to(point: Vector2) -> void:
	global_position = point
	velocity = Vector2.ZERO
	_coyote_left = 0.0
	_buffer_left = 0.0
	controls_enabled = true
