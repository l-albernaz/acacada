extends Node

var current_character = null
var characters = []  # Lista de personagens (Mancha e Lupu)

@onready var turn_overlay: ColorRect = $TurnOverlay  # Referência ao ColorRect
@onready var turn_label: Label = $TurnLabel  # Referência ao Label da mensagem
@onready var steps_label: Label = $stepsLabel  # Referência ao Label dos passos restantes

func _ready():
	characters = get_tree().get_nodes_in_group("players")
	if characters.size() > 0:
		current_character = characters[1]  # Lupu começa jogando
		current_character.enable_control(true)
		
		turn_overlay.modulate.a = 0.5  # Começa escuro (turno do Lupu)
		turn_label.visible = false  # Oculta a mensagem no início
		update_overlay()
		update_steps_label()  # Atualiza o contador no início

func end_turn():
	if characters.size() < 2:
		return  

	# Desativa o controle do personagem atual
	current_character.enable_control(false)

	# Alterna entre Mancha (index 0) e Lupu (index 1)
	var index = (characters.find(current_character) + 1) % characters.size()
	current_character = characters[index]

	# Atualiza o efeito visual do turno antes de liberar o próximo jogador
	await update_overlay()

	# Mostra a mensagem "É a vez do próximo jogador"
	turn_label.text = "É a vez do próximo jogador"
	turn_label.visible = true

	# Aguarda 1 segundo antes de realmente liberar o movimento do novo jogador
	await get_tree().create_timer(1.0).timeout

	# Oculta a mensagem antes de liberar o próximo jogador
	turn_label.visible = false

	# Ativa o controle do próximo personagem
	current_character.enable_control(true)

	# Reseta o contador de passos no novo turno
	update_steps_label()

func update_overlay():
	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

	if current_character.name.to_lower() == "mancha":
		tween.tween_property(turn_overlay, "modulate:a", 0, 0.5)  # Clareia
	else:
		tween.tween_property(turn_overlay, "modulate:a", 0.5, 0.5)  # Escurece

	# Aguarda a conclusão da transição antes de continuar
	await tween.finished

func update_steps_label():
	# Atualiza o texto do Label com base nos movimentos restantes do personagem atual
	if current_character:
		var remaining_steps = max(current_character.max_moves - current_character.move_count, 0)
		steps_label.text = "Ainda há %d passos restantes" % remaining_steps

func end_game(winner: String):
	print("O jogo acabou! Vencedor: " + winner)
	
	# Garante que o Lupu fique visível ao perder
	var lupu = get_tree().get_nodes_in_group("lupu").front()
	
	# Exibe uma mensagem de vitória
	turn_label.text = winner + " venceu!"
	turn_label.visible = true

	# Desativa o controle de todos os personagens
	for character in characters:
		character.enable_control(false)

	# Aguarda 3 segundos antes de fechar o jogo
	await get_tree().create_timer(3.0).timeout
	
	# Fecha o jogo
	get_tree().quit()
