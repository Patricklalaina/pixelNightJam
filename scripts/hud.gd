extends CanvasLayer

signal level_started(total_time: float)
signal level_tick(time_left: float)
signal level_timeout

@onready var timer: Timer = $Timer
@onready var label: Label = $time
@onready var score_label: Label = $ScoreLabel as Label
func _ready() -> void:
	add_to_group("HUD")
	timer.one_shot = true
	if not timer.timeout.is_connected(_on_timer_timeout):
		timer.timeout.connect(_on_timer_timeout)
	label.text = _fmt(timer.wait_time)
	if score_label:
		score_label.text = str(GameManager.score)
	GameManager.score_changed.connect(_on_score_changed)

func _on_score_changed(new_score: int) -> void:
	if score_label:
		score_label.text = str(new_score)

func start_level_timer(duration: float = -1.0) -> void:
	if duration > 0:
		timer.wait_time = duration
	label.text = _fmt(timer.wait_time)
	timer.start()
	emit_signal("level_started", timer.wait_time)

func stop_level_timer() -> void:
	if not timer.is_stopped():
		timer.stop()
	label.text = "00:00"

func _process(delta: float) -> void:
	if not timer.is_stopped():
		label.text = _fmt(timer.time_left)
		emit_signal("level_tick", timer.time_left)

func _on_timer_timeout() -> void:
	label.text = "00:00"
	emit_signal("level_timeout")

func _fmt(t: float) -> String:
	var total := int(ceil(max(t, 0.0)))
	var m := int(total / 60)
	var s := int(total % 60)
	return str(m).pad_zeros(2) + ":" + str(s).pad_zeros(2)
