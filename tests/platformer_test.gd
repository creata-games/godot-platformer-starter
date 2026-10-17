extends SceneTree
## Проверка механики без окна:
##   godot --headless --path . -s tests/platformer_test.gd
## Загружаем уровень, ждём физические кадры (физика считается в них, а не в обычных).

var failures := 0


func check(cond: bool, what: String) -> void:
	print(("  OK   " if cond else "  FAIL ") + what)
	if not cond:
		failures += 1


func frames(n: int) -> void:
	for i in n:
		await physics_frame


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	change_scene_to_file("res://scenes/main.tscn")
	await process_frame
	await process_frame
	var main: Node2D = current_scene
	var player: CharacterBody2D = main.get_node("Player")

	# 1. Игрок падает на платформу и стоит.
	await frames(90)
	check(player.is_on_floor(), "игрок стоит на платформе")
	check(absf(player.global_position.y - 556.0) < 2.0, "ноги на уровне верха платформы (y=%.1f)" % player.global_position.y)
	check(absf(player.velocity.y) < 1.0, "стоя, вертикальная скорость ~0")

	# 2. Прыжок поднимает игрока.
	var start_y := player.global_position.y
	var min_y := start_y
	Input.action_press("jump")
	await frames(2)
	Input.action_release("jump")
	for i in 40:
		await physics_frame
		min_y = minf(min_y, player.global_position.y)
	check(start_y - min_y > 80.0, "прыжок поднял игрока на %.0f px" % (start_y - min_y))
	await frames(60)
	check(player.is_on_floor(), "после прыжка игрок снова на земле")

	# 3. Бег вправо двигает игрока.
	var x0 := player.global_position.x
	Input.action_press("move_right")
	await frames(20)
	Input.action_release("move_right")
	check(player.global_position.x > x0 + 50.0, "бег вправо сдвинул игрока")

	# 4. Падение ниже порога вызывает рестарт.
	var restarts: int = main.restart_count
	player.global_position = Vector2(300, main.fall_limit_y + 50.0)
	await frames(3)
	check(main.restart_count == restarts + 1, "падение за край вызвало рестарт")
	check(player.global_position.y < main.fall_limit_y and player.global_position.x < 100.0, "игрок вернулся на старт")

	# 5. Касание финиша выставляет флаг победы.
	check(not main.won, "до финиша победы нет")
	player.global_position = main.get_node("Goal").global_position
	await frames(3)
	check(main.won, "касание посылки выставило флаг победы")
	check(main.get_node("UI/WinLabel").visible, "экран «уровень пройден» показан")

	# 6. R сбрасывает победу.
	Input.action_press("restart")
	await frames(3)
	Input.action_release("restart")
	check(not main.won and not main.get_node("UI/WinLabel").visible, "R перезапустила уровень после победы")

	# 7. Койот-тайм: сразу после схода с края прыжок ещё работает.
	await frames(60)
	player.global_position = Vector2(425, 556)  # за краем первой платформы (она кончается на x=400)
	player.velocity = Vector2.ZERO
	await frames(2)  # уже в воздухе: пол пропал
	check(not player.is_on_floor(), "игрок сошёл с края")
	Input.action_press("jump")
	await frames(2)
	Input.action_release("jump")
	check(player.velocity.y < 0.0, "койот-тайм: прыжок сработал после схода с края")

	print("ИТОГ: %s (провалов: %d)" % ["OK" if failures == 0 else "FAIL", failures])
	quit(1 if failures else 0)
