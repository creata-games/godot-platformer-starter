extends Node2D
## Правила уровня: падение за край, финиш, рестарт по R.

## Если игрок упал ниже этой линии (координата Y), уровень начинается заново.
@export var fall_limit_y: float = 800.0

## Поднялся в true, когда игрок дотронулся до посылки.
var won := false
## Сколько раз уровень перезапускался (нужно тестам).
var restart_count := 0

var _spawn_point: Vector2

@onready var player: CharacterBody2D = $Player
@onready var goal: Area2D = $Goal
@onready var win_label: Label = $UI/WinLabel


func _ready() -> void:
	_spawn_point = player.global_position
	goal.body_entered.connect(_on_goal_body_entered)


func _physics_process(_delta: float) -> void:
	if player.global_position.y > fall_limit_y:
		restart()


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		restart()


func _on_goal_body_entered(body: Node) -> void:
	if body == player and not won:
		won = true
		player.controls_enabled = false
		win_label.visible = true


func restart() -> void:
	restart_count += 1
	won = false
	win_label.visible = false
	player.reset_to(_spawn_point)
