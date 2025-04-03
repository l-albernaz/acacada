extends CharacterBody2D

const TILE_SIZE = 65  
var direction = Vector2.ZERO
var moving = false  
var can_move = false  
var move_count = 0  
var max_moves = 3  
var speed = 300  

@onready var game_manager = get_parent()  

func enable_control(state):
	can_move = state  
	if state:
		move_count = 0  
		game_manager.update_steps_label()  # Atualiza os passos restantes na interface

func _ready():
	position = position.snapped(Vector2(TILE_SIZE, TILE_SIZE))  
	add_to_group("players")  

	# **Desativa a colisão da Mancha com o Lupu**
	set_collision_mask_value(2, false)  # Supondo que Lupu esteja na layer 2
	set_collision_layer_value(2, false)

func _unhandled_input(event):
	if not can_move or moving:
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

func _on_move_complete():
	moving = false
	velocity = Vector2.ZERO  
	move_count += 1  

	game_manager.update_steps_label()  # Atualiza o contador de passos

	check_same_tile()

	if move_count >= max_moves:
		game_manager.end_turn()

func check_same_tile():
	var players = get_tree().get_nodes_in_group("players")
	for player in players:
		if player != self and player.position == self.position:
			game_manager.end_game("Mancha")  # Mancha venceu!
