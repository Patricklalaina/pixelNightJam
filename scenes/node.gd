extends Control

@onready var timer: Timer = $Timer
@onready var progress: ProgressBar = $ProgressBar

func _ready():
	progress.min_value = 0
	progress.max_value = timer.wait_time
	progress.value = timer.wait_time

func start_timer():
	timer.start()
	progress.value = timer.wait_time

func _process(delta: float) -> void:
	if timer.time_left > 0:
		progress.value = timer.time_left
	else:
		progress.value = 0

func _on_timer_timeout() -> void:
	print("Timer terminé !")
	progress.value = 0
	visible = false
	GameManager.timeOut = true
