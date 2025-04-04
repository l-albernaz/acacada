extends CharacterBody2D

const TILE_SIZE = 65  
var direction = Vector2.ZERO
var moving = false  
var can_move = false  
var move_count = 0  

@export var max_moves: int = 2
@export var shadows_per_turn: int = 2
@export var rounds_before_shadows: int = 2
@export var hide_lupu_after_move: bool = true

@onready var shadow_scene = preload("res://LupuShadow.tscn")
@onready var game_manager = get_parent()

var first_move_done = false  
var round_count = 0  

func enable_control(state):
	can_move = state
	if state:
		move_count = 0
		game_manager.update_steps_label()

func _ready():
	position = position.snapped(Vector2(TILE_SIZE, TILE_SIZE))
	add_to_group("players")

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
	if move_count >= max_moves:
		return

	var target_position = position + (direction * TILE_SIZE)

	if is_position_blocked(target_position):
		print("Movimento bloqueado!")
		return

	if test_move(transform, direction * TILE_SIZE):
		print("Colisão detectada!")
		return
	
	moving = true
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "position", target_position, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_on_move_complete)

	# Verificar se o Lupu está preso após o movimento
	if check_if_trapped():
		game_manager.end_game()  # Finaliza o jogo se estiver preso

func _on_move_complete():
	moving = false
	move_count += 1
	game_manager.update_steps_label()

	if not first_move_done:
		first_move_done = true
		if hide_lupu_after_move:
			self.visible = false

	if move_count >= max_moves:
		round_count += 1
		if round_count % rounds_before_shadows == 0:
			create_shadows()
		
		game_manager.end_turn()

func create_shadows():
	var available_positions = []

	for x_offset in range(-2, 3):
		for y_offset in range(-2, 3):
			var offset = Vector2(x_offset, y_offset)
			if offset == Vector2.ZERO:
				continue  # Ignora a posição atual do personagem
			
			var pos = position + offset * TILE_SIZE
			if not is_position_blocked(pos) and not is_shadow_present(pos):
				available_positions.append(pos)

	available_positions.shuffle()
	var selected_positions = available_positions.slice(0, shadows_per_turn)

	for pos in selected_positions:
		var shadow = shadow_scene.instantiate()
		shadow.position = pos
		shadow.add_to_group("shadows")  
		get_parent().add_child(shadow)

func is_position_blocked(target_pos) -> bool:
	# Ignora colisões com o próprio Lupu
	if self.position == target_pos:
		return false

	# Verifica as colisões com objetos sólidos
	for obj in get_tree().get_nodes_in_group("solid_objects"):
		if obj.position == target_pos:
			return true

	return false

func is_shadow_present(target_pos) -> bool:
	for shadow in get_tree().get_nodes_in_group("shadows"):
		if shadow.position == target_pos:
			return true
	return false

# Método para verificar se o Lupu está preso
func check_if_trapped() -> bool:
	var directions = [
		Vector2(0, -1),  # Para cima
		Vector2(0, 1),   # Para baixo
		Vector2(-1, 0),  # Para a esquerda
		Vector2(1, 0)    # Para a direita
	]
	
	# Verifica se todas as direções estão bloqueadas
	for dir in directions:
		var target_position = position + dir * TILE_SIZE
		if not is_position_blocked(target_position):
			return false  # Se alguma direção não estiver bloqueada, Lupu não está preso
	
	return true  # Se todas as direções estão bloqueadas, Lupu está preso
