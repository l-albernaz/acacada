extends CharacterBody2D

const TILE_SIZE = 65  
var direction = Vector2.ZERO
var moving = false  
var can_move = false  
var move_count = 0  
const MAX_MOVES = 1  

func enable_control(state):
	can_move = state  
	if state:
		move_count = 0  

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
	var target_position = position + (direction * TILE_SIZE)

	var collision = move_and_collide(direction * TILE_SIZE)
	if collision:
		return 
	
	moving = true
	
	var tween = get_tree().create_tween()
	tween.tween_property(self, "position", target_position, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_on_move_complete)

func _on_move_complete():
	# Atualiza o overlay e espera o efeito terminar antes de continuar
	await get_parent().update_overlay()

	await get_tree().create_timer(1.0).timeout  # Espera 1 segundo após o efeito
	
	moving = false
	move_count += 1  

	if move_count >= MAX_MOVES:
		get_parent().end_turn()
