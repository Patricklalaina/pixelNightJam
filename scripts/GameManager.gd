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

# Indique si le prochain chargement de game.tscn démarre un nouveau run (score=0, level=1)
var new_run: bool = true

# Score
signal score_changed(new_score: int)
var score: int = 0

# ====== Système de niveaux ======
signal level_changed(level: int, quota: int, time_limit: float)

var level: int = 1
var level_start_score: int = 0
var last_passed_level: int = 0  # pour l'écran de transition

# Paramètres (ajustables)
var base_quota: int = 10           # quota niveau 1 (ta demande)
var quota_growth: float = 1.50     # quota augmente par niveau (ex: +50%)
var base_time: float = 50.0        # timer niveau 1 en secondes (ta demande)
var time_growth: float = 1.10      # le timer augmente par niveau (ex: +10% ou ajuste à ton goût)

func get_level_quota(l: int = level) -> int:
	var q := float(base_quota) * pow(quota_growth, float(max(0, l - 1)))
	return max(1, int(ceil(q)))

func get_level_time(l: int = level) -> float:
	var t := float(base_time) * pow(time_growth, float(max(0, l - 1)))
	return max(1.0, t)

func get_level_progress_score() -> int:
	return max(0, score - level_start_score)

func get_level_quota_current() -> int:
	return get_level_quota(level)

func has_met_quota() -> bool:
	return get_level_progress_score() >= get_level_quota_current()

# ====== Stats persistantes ======
const STATS_PATH := "user://stats.json"
signal stats_updated
var stats: Array[Dictionary] = []  # {"score": int, "won": bool, "date": String}

func _ready() -> void:
	load_stats()

# ====== Score API ======
func add_score(amount: int) -> void:
	score = max(0, score + amount)
	score_changed.emit(score)
	# Passage immédiat si quota atteint -> transition niveau
	if has_met_quota() and not gameOver:
		perform_level_up_transition()

func reset_score() -> void:
	score = 0
	score_changed.emit(score)

# ====== Gestion de partie / niveaux ======
func start_new_game() -> void:
	gameOver = false
	reset_player_state()
	reset_score()
	level = 1
	level_start_score = 0
	new_run = false
	_emit_level_changed()

func _prepare_next_level() -> void:
	# Pose last_passed_level puis incrémente
	last_passed_level = level
	level += 1
	level_start_score = score

func start_next_level() -> void:
	# Public si besoin (n’incrémente QUE si tu le veux manuellement)
	_prepare_next_level()
	_emit_level_changed()

func _emit_level_changed() -> void:
	var quota := get_level_quota(level)
	var time_limit := get_level_time(level)
	level_changed.emit(level, quota, time_limit)

func perform_level_up_transition() -> void:
	# Transition: prépare le prochain niveau et va sur win.tscn
	_prepare_next_level()
	get_tree().change_scene_to_file("res://scenes/win.tscn")

# ====== Etat joueur (existant) ======
func reset_player_state() -> void:
	hidePL = false
	hideAnimationOK = false
	timeOut = false
	show = true
	isMaximizing = false
	timerActive = false

func start_hiding_sequence() -> void:
	hidePL = true
	hideAnimationOK = false
	timeOut = false
	isMaximizing = false
	timerActive = true

func complete_sequence() -> void:
	hidePL = false
	hideAnimationOK = false
	timeOut = false
	isMaximizing = false
	timerActive = false

func lose_game() -> void:
	if gameOver:
		return
	gameOver = true
	print("Défaite: le joueur a été attrapé.")
	emit_signal("player_caught")
	# get_tree().paused = true

# ====== Utility Audio (existant) ======
func _play_msc(stream: AudioStreamPlayer2D) -> void:
	stream.play()
	await get_tree().create_timer(1.2).timeout
	print("OK pret")

# ====== API Stats (existant) ======
func record_game_result(final_score: int, won: bool) -> void:
	if stats.is_empty():
		load_stats()
	var entry: Dictionary = {
		"score": int(final_score),
		"won": bool(won),
		"date": Time.get_datetime_string_from_system(true)
	}
	stats.append(entry)
	save_stats()
	stats_updated.emit()
	# Fin de run
	new_run = true

func load_stats() -> void:
	stats.clear()
	if FileAccess.file_exists(STATS_PATH):
		var f := FileAccess.open(STATS_PATH, FileAccess.READ)
		if f:
			var txt := f.get_as_text()
			f.close()
			var parsed = JSON.parse_string(txt)
			if parsed is Array:
				for v in (parsed as Array):
					if v is Dictionary:
						stats.append(v as Dictionary)

func save_stats() -> void:
	var f := FileAccess.open(STATS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(stats))
		f.close()

func get_stats_table_text() -> String:
	var lines: Array[String] = []
	lines.append("No  | Date & Heure         | Résultat   | Score")
	lines.append("----+-----------------------+------------+------")
	for i in range(stats.size()):
		var e: Dictionary = stats[i]
		var num := str(i + 1).pad_zeros(2)
		var date := String(e.get("date", ""))
		var won := bool(e.get("won", false))
		var res := "Win" if won else "Game Over"
		var sc := str(int(e.get("score", 0)))
		var line := "%s | %s | %10s | %s" % [num, date, res, sc]
		lines.append(line)
	return "\n".join(lines)

func get_stats_bbcode() -> String:
	var lines: Array[String] = []
	lines.append("[b]Historique des parties[/b]")
	if stats.is_empty():
		lines.append("[color=#888]Aucune partie enregistrée pour le moment.[/color]")
		return "\n".join(lines)

	for i in range(stats.size()):
		var e: Dictionary = stats[i]
		var num := str(i + 1).pad_zeros(2)
		var date := String(e.get("date", ""))
		var won := bool(e.get("won", false))
		var res_badge := "[color=#35c46a]✓ Win[/color]" if won else "[color=#e25555]✖ Game Over[/color]"
		var sc := str(int(e.get("score", 0)))
		lines.append("• [b]Partie %s[/b] — %s — [b]%s[/b] pts — [color=#888]%s[/color]" % [num, res_badge, sc, date])
	return "\n".join(lines)
