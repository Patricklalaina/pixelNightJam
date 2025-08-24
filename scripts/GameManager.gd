extends Node

signal player_caught  # émis quand un ennemi attrape le joueur

@onready var hidePL: bool = false
@onready var hideAnimationOK: bool = false
@onready var timeOut: bool = false
@onready var show: bool = true
@onready var isMaximizing: bool = false
@onready var timerActive: bool = false  # timer de cachette
@onready var volume_music: float = -6
@onready var volume_audio: float = 0.0
@onready var tmpOBJ = null

# Etat jeu
@onready var gameOver: bool = false

signal score_changed(new_score: int)
var score: int = 0

func add_score(amount: int) -> void:
	score = max(0, score + amount)
	score_changed.emit(score)

func reset_score() -> void:
	score = 0
	score_changed.emit(score)

func start_new_game() -> void:
	gameOver = false
	reset_player_state()
	reset_score()

func reset_player_state():
	hidePL = false
	hideAnimationOK = false
	timeOut = false
	show = true
	isMaximizing = false
	timerActive = false

func start_hiding_sequence():
	hidePL = true
	hideAnimationOK = false
	timeOut = false
	isMaximizing = false
	timerActive = true

func complete_sequence():
	hidePL = false
	hideAnimationOK = false
	timeOut = false
	isMaximizing = false
	timerActive = false

func lose_game():
	if gameOver:
		return
	gameOver = true
	print("Défaite: le joueur a été attrapé.")
	emit_signal("player_caught")
	# Option: mettre en pause ou changer de scène
	# get_tree().paused = true
	# get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _play_msc(stream: AudioStreamPlayer2D) -> void:
	stream.play()
	# Attendre la durée complète
	await get_tree().create_timer(1.2).timeout
	print("OK pret")
