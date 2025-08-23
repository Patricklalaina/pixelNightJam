extends Node

@onready var hidePL: bool = false
@onready var hideAnimationOK: bool = false
@onready var timeOut: bool = false
@onready var show: bool = true
@onready var isMaximizing: bool = false
@onready var timerActive: bool = false  # Nouveau flag pour contrôler le timer

@onready var tmpOBJ = null

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

func _play_msc(stream: AudioStreamPlayer2D) -> void:
	stream.play()
	# Attendre la durée complète
	await get_tree().create_timer(1.2).timeout
	print("OK pret")
