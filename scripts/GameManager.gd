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

# ====== Stats persistantes ======
const STATS_PATH := "user://stats.json"
signal stats_updated
var stats: Array[Dictionary] = []  # chaque entrée: {"score": int, "won": bool, "date": String}

func _ready() -> void:
	load_stats()

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
	# Option: mettre en pause ou changer de scène
	# get_tree().paused = true
	# get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _play_msc(stream: AudioStreamPlayer2D) -> void:
	stream.play()
	# Attendre la durée complète
	await get_tree().create_timer(1.2).timeout
	print("OK pret")

# ====== API Stats ======
func record_game_result(final_score: int, won: bool) -> void:
	# S'assurer que stats est chargée
	if stats.is_empty():
		load_stats()
	var entry: Dictionary = {
		"score": int(final_score),
		"won": bool(won),
		"date": Time.get_datetime_string_from_system(true)  # "YYYY-MM-DD HH:MM:SS"
	}
	stats.append(entry)
	save_stats()
	stats_updated.emit()

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
