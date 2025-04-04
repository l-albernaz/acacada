extends CharacterBody2D

const TILE_SIZE = 65
var direction = Vector2.ZERO
var moving = false
var can_move = false
var move_count = 0
var max_moves = 4
var speed = 300

@onready var game_manager = get_parent()

func enable_control(state):
	can_move = state
	if state:
		move_count = 0
		game_manager.update_steps_label()

func _ready():
	position = position.snapped(Vector2(TILE_SIZE, TILE_SIZE))
	add_to_group("players")

	# Permitir que Mancha ande sobre o Lupu
	set_collision_mask_value(2, false)
	set_collision_layer_value(2, false)

func _unhandled_input(event):
	if not can_move or moving or game_manager.game_over:
		return

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_UP:
			direction = Vector2(0, -1)
		elif event.keycode == KEY_DOWN:
			direction = Vector2(0, 1)
		elif event.keycode == KEY_LEFT:
			direction = Vector2(-1, 0)
		elif event.keycode == KEY_RIGHT:
			direction = Vector2(1, 0)
		else:
			return

		move()

func move():
	if moving:
		return

	moving = true
	velocity = direction * speed
	await get_tree().create_timer(0.2).timeout
	_on_move_complete()

func _physics_process(delta):
	if moving:
		move_and_slide()
		check_same_tile()  # Checa durante o movimento também

func _on_move_complete():
	moving = false
	velocity = Vector2.ZERO
	position = position.snapped(Vector2(TILE_SIZE, TILE_SIZE))  # Garante alinhamento com a grade
	move_count += 1
	game_manager.update_steps_label()

	check_same_tile()  # Verifica ao fim do movimento também

	if move_count >= max_moves and not game_manager.game_over:
		game_manager.end_turn()

func check_same_tile():
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		if player.name.to_lower() == "lupu":
			# Verifica se Mancha e Lupu estão na mesma posição com margem de erro
			if is_equal_approx(player.position.x, self.position.x) and is_equal_approx(player.position.y, self.position.y):
				game_manager.end_game("Mancha")
