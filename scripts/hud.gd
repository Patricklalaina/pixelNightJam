extends CanvasLayer

signal level_started(total_time: float)
signal level_tick(time_left: float)
signal level_timeout

@onready var timer: Timer = $Timer
@onready var label: Label = $time
@onready var score_label: Label = $ScoreLabel as Label

# Optionnels si présents
@onready var level_label: Label = get_node_or_null("LevelLabel")
@onready var quota_label: Label = get_node_or_null("QuotaLabel")

var _current_quota: int = 0

func _ready() -> void:
	add_to_group("HUD")
	timer.one_shot = true
	if not timer.timeout.is_connected(_on_timer_timeout):
		timer.timeout.connect(_on_timer_timeout)
	label.text = _fmt(timer.wait_time)

	if not GameManager.score_changed.is_connected(_on_score_changed):
		GameManager.score_changed.connect(_on_score_changed)
	if not GameManager.level_changed.is_connected(_on_level_changed):
		GameManager.level_changed.connect(_on_level_changed)

	_current_quota = GameManager.get_level_quota_current()
	_update_level_labels()

	# Affiche progression "x/y"
	if score_label:
		score_label.text = str(GameManager.get_level_progress_score()) + "/" + str(_current_quota)

func _on_level_changed(level: int, quota: int, time_limit: float) -> void:
	_current_quota = quota
	_update_level_labels()
	_on_score_changed(GameManager.score)  # refresh x/y

func _update_level_labels() -> void:
	if level_label:
		level_label.text = "Niveau: " + str(GameManager.level)
	if quota_label:
		quota_label.text = "Quota: " + str(_current_quota)

func _on_score_changed(new_score: int) -> void:
	if score_label:
		var prog := GameManager.get_level_progress_score()
		var q := GameManager.get_level_quota_current()
		score_label.text = str(prog) + "/" + str(q)

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
