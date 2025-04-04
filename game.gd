extends Node

@export var shadow_win_threshold: int = 25  # Número mínimo de Shadows para Lupu vencer
var current_character = null
var characters = []
var game_over = false  # Impede múltiplas vitórias

@onready var turn_overlay: ColorRect = $TurnOverlay
@onready var turn_label: Label = $TurnLabel
@onready var steps_label: Label = $stepsLabel

func _ready():
	characters = get_tree().get_nodes_in_group("players")
	if characters.size() > 0:
		current_character = characters[1]  # Lupu começa jogando
		current_character.enable_control(true)
		
		turn_overlay.modulate.a = 0.5
		turn_label.visible = false
		update_overlay()
		update_steps_label()

	check_shadow_win()  # Verifica vitória no início

func end_turn():
	if game_over or characters.size() < 2:
		return

	if check_shadow_win():
		return

	current_character.enable_control(false)

	var index = (characters.find(current_character) + 1) % characters.size()
	current_character = characters[index]

	await update_overlay()

	turn_label.text = "É a vez do próximo jogador"
	turn_label.visible = true

	await get_tree().create_timer(1.0).timeout

	turn_label.visible = false
	current_character.enable_control(true)
	update_steps_label()

	check_shadow_win()

func update_overlay():
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

	if current_character.name.to_lower() == "mancha":
		tween.tween_property(turn_overlay, "modulate:a", 0, 0.5)
	else:
		tween.tween_property(turn_overlay, "modulate:a", 0.5, 0.5)

	await tween.finished

func update_steps_label():
	if current_character:
		var remaining_steps = max(current_character.max_moves - current_character.move_count, 0)
		steps_label.text = "Ainda há %d passos restantes" % remaining_steps

func check_shadow_win() -> bool:
	if game_over:
		return false

	var shadow_list = get_tree().get_nodes_in_group("shadows")
	print("Número de Shadows detectados:", shadow_list.size())

	if shadow_list.size() >= shadow_win_threshold:
		end_game("Lupu")
		return true
	return false

func end_game(winner: String):
	if game_over:
		return

	game_over = true
	print("O jogo acabou! Vencedor: " + winner)

	turn_label.text = winner + " venceu!"
	turn_label.visible = true

	for character in characters:
		character.enable_control(false)

	await get_tree().create_timer(3.0).timeout
	get_tree().quit()
