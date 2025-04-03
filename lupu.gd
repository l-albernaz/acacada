extends CharacterBody2D

const TILE_SIZE = 65  
var direction = Vector2.ZERO
var moving = false  
var can_move = false  
var move_count = 0  

@export var max_moves: int = 2  # Número de movimentos por rodada (agora ajustável no Inspetor)
@export var shadows_per_turn: int = 2  # Número de sombras geradas após o tempo definido
@export var rounds_before_shadows: int = 2  # Número de rodadas antes das sombras aparecerem
@export var hide_lupu_after_move: bool = true  # Alterna a visibilidade de Lupu no Inspetor

@onready var shadow_scene = preload("res://LupuShadow.tscn")  
@onready var game_manager = get_parent()  # Referência ao Game Manager

var first_move_done = false  
var round_count = 0  # Contador de rodadas

func enable_control(state):
	can_move = state  
	if state:
		move_count = 0  
		game_manager.update_steps_label()  # Atualiza a contagem no início do turno

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

	# Verifica se a Mancha ou outro objeto sólido está na posição alvo
	if is_position_blocked(target_position):
		print("Movimento bloqueado!")  # Apenas para depuração
		return  # Cancela o movimento sem gastar uma ação

	# Simula um movimento para ver se há colisão antes de mover
	if test_move(transform, direction * TILE_SIZE):
		print("Colisão detectada!")  # Apenas para depuração
		return  
	
	moving = true
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "position", target_position, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_on_move_complete)

func _on_move_complete():

	moving = false
	move_count += 1  

	# Atualiza a label de passos restantes sempre que Lupu se move
	game_manager.update_steps_label()

	if not first_move_done:
		first_move_done = true
		if hide_lupu_after_move:
			self.visible = false  # Lupu fica invisível após o primeiro movimento, se a opção estiver ativada

	# Se atingiu o número máximo de movimentos, passa o turno
	if move_count >= max_moves:
		round_count += 1  # Conta uma rodada completa

		# Cria sombras apenas após o número de rodadas definido
		if round_count % rounds_before_shadows == 0:
			create_shadows()
		
		game_manager.end_turn()

func create_shadows():
	var possible_positions = [
		position + Vector2(0, -TILE_SIZE),  # Cima
		position + Vector2(0, TILE_SIZE),   # Baixo
		position + Vector2(-TILE_SIZE, 0),  # Esquerda
		position + Vector2(TILE_SIZE, 0),   # Direita
		position + Vector2(-TILE_SIZE, -TILE_SIZE),  # Canto superior esquerdo
		position + Vector2(TILE_SIZE, -TILE_SIZE),   # Canto superior direito
		position + Vector2(-TILE_SIZE, TILE_SIZE),   # Canto inferior esquerdo
		position + Vector2(TILE_SIZE, TILE_SIZE)     # Canto inferior direito
	]

	# Filtra posições ocupadas
	var available_positions = []
	for pos in possible_positions:
		if not is_position_blocked(pos):  # Agora a função verifica qualquer bloqueio
			available_positions.append(pos)

	# Seleciona exatamente a quantidade de sombras definida no Inspetor
	available_positions.shuffle()
	var selected_positions = available_positions.slice(0, shadows_per_turn)  

	for pos in selected_positions:
		var shadow = shadow_scene.instantiate()
		shadow.position = pos
		get_parent().add_child(shadow)

func is_position_blocked(target_pos) -> bool:
	# Verifica se há alguma Mancha ou outro objeto sólido bloqueando a posição
	for obj in get_tree().get_nodes_in_group("solid_objects"):
		if obj.position == target_pos:
			return true
	return false
