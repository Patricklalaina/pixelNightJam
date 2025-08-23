#extends Control
#
#@onready var timer: Timer = $Timer
#@onready var progress: ProgressBar = $ProgressBar
#
#func _ready():
	#progress.min_value = 0
	#progress.max_value = timer.wait_time
	#progress.value = timer.wait_time
#
#func start_timer():
	#timer.start()
	#progress.value = timer.wait_time
#
#func _process(delta: float) -> void:
	#if timer.time_left > 0:
		#progress.value = timer.time_left
	#else:
		#progress.value = 0
#
#func _on_timer_timeout() -> void:
	#print("Timer terminé !")
	#progress.value = 0
	#visible = false
	#GameManager.timeOut = true

extends Control

@onready var timer: Timer = $Timer
@onready var progress: ProgressBar = $ProgressBar

func _ready():
	progress.min_value = 0
	progress.max_value = timer.wait_time
	progress.value = timer.wait_time
	timer.one_shot = true  # S'assurer que le timer ne se répète pas

func start_timer():
	if not timer.is_stopped():
		timer.stop()  # Arrêter le timer s'il était déjà en cours
	
	timer.start()
	progress.value = timer.wait_time
	print("Timer démarré pour ", timer.wait_time, " secondes")

func _process(delta: float) -> void:
	if GameManager.timerActive and not timer.is_stopped():
		progress.value = timer.time_left
	else:
		if GameManager.timerActive:
			progress.value = 0

func _on_timer_timeout() -> void:
	print("Timer terminé !")
	if GameManager.timerActive:  # Vérifier que le timer était actif
		progress.value = 0
		visible = false
		GameManager.timeOut = true
		
		# Réinitialiser l'objet temporaire si nécessaire
		if GameManager.tmpOBJ != null:
			GameManager.tmpOBJ.play("normal")
		
		print("Timer timeout traité - timeOut activé")

func stop_timer():
	timer.stop()
	progress.value = 0
	visible = false
