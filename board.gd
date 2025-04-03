extends Sprite2D

const BOARD_SIZE = 8

const FUMAÇA = preload("res://assets/fumaça.png")
const LUPUNOCTIS = preload("res://assets/Lupunoctis.png")
const MANCHA = preload("res://assets/Mancha.png")

const TURNOLUPU = preload("res://assets/turnolupu.png")
const TURNOMANCHA = preload("res://assets/turnomancha.png")

@onready var pecas: Node2D = $pecas
@onready var pontos: Node2D = $pontos
@onready var turno: Sprite2D = $turno

var board: Array
