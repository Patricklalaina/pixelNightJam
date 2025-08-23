extends CanvasLayer

signal level_started(total_time: float)
signal level_tick(time_left: float)
signal level_timeout

@onready var timer: Timer = $Timer
@onready var label: Label = $time

func _ready() -> void:
	add_to_group("LevelTimer")
	GameManager.hud_level = self
	timer.one_shot = true
	if label:
		label.text = _format_time(timer.wait_time)
	timer.timeout.connect(_on_timer_timeout)

func start_level_timer(duration: float = -1.0) -> void:
	if duration > 0:
		timer.wait_time = duration
	if label:
		label.text = _format_time(timer.wait_time)
	timer.start()
	GameManager.level_timer_active = true
	GameManager.level_time_total = timer.wait_time
	GameManager.level_time_left = timer.wait_time
	emit_signal("level_started", timer.wait_time)

func stop_level_timer() -> void:
	if not timer.is_stopped():
		timer.stop()
	if label:
		label.text = "00:00"
	GameManager.level_timer_active = false

func _process(delta: float) -> void:
	if GameManager.level_timer_active and not timer.is_stopped():
		GameManager.level_time_left = timer.time_left
		if label:
			label.text = _format_time(timer.time_left)
		emit_signal("level_tick", timer.time_left)

func _on_timer_timeout() -> void:
	if label:
		label.text = "00:00"
	GameManager.level_timer_active = false
	GameManager.level_time_left = 0
	GameManager.win_level()
	emit_signal("level_timeout")

func _format_time(t: float) -> String:
	var total := int(ceil(max(t, 0.0)))
	var m := int(total / 60)
	var s := int(total % 60)
	return str(m).pad_zeros(2) + ":" + str(s).pad_zeros(2)
