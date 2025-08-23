#extends Control
#
#@onready var minus: Button = $HSplitContainer/minus
#@onready var music: ProgressBar = $HSplitContainer/music
#@onready var plus: Button = $HSplitContainer/plus
#@onready var minus1: Button = $HSplitContainer2/minus
#@onready var audio: ProgressBar = $HSplitContainer2/audio
#@onready var plus2: Button = $HSplitContainer2/plus
#
#const MIN_DB := -80.0
#const MAX_DB := 0.0 # recommande 0 dB max pour éviter le clipping (mets 6.0 si tu veux autoriser +6 dB)
#
#func percent_to_db_perceptual(pct: float) -> float:
	#pct = clamp(pct, 0.0, 100.0)
	#var a_min = db_to_linear(MIN_DB)   # ~0.0001
	#var a_max = db_to_linear(MAX_DB)   # 1.0 si 0 dB, ~1.995 si 6 dB
	#var a = lerp(a_min, a_max, pct / 100.0)
	#return linear_to_db(a)
#
#func db_to_percent_perceptual(db: float) -> float:
	#var a_min := db_to_linear(MIN_DB)
	#var a_max := db_to_linear(MAX_DB)
	#var a := db_to_linear(db)
	#return clamp(inverse_lerp(a_min, a_max, a) * 100.0, 0.0, 100.0)
#
#func set_bus_volume_percent(bus_name: String, pct: float) -> void:
	#var bus_idx = AudioServer.get_bus_index(bus_name)
	#var db = percent_to_db_perceptual(pct)
	#AudioServer.set_bus_volume_db(bus_idx, db)
#
#func _ready() -> void:
	#var bus_idxBG = AudioServer.get_bus_index("BG_music")
	#var dbBG = GameManager.volume_music
	#AudioServer.set_bus_volume_db(bus_idxBG, dbBG)
	#var bus_idx = AudioServer.get_bus_index("pl_btn")
	#var db = GameManager.volume_audio
	#AudioServer.set_bus_volume_db(bus_idx, db)
	#music.value = percent_to_db_perceptual(GameManager.volume_music)
	#audio.value = percent_to_db_perceptual(GameManager.volume_audio)
	#print(music.value)
#func _on_minus_pressed() -> void:
	#if music.value <= 20:
		#return 
	#print("Ato")
	#music.value -= 20
	#GameManager.volume_music = db_to_percent_perceptual(music.value)
	#set_bus_volume_percent("BG_music", music.value)
#
#
#func _on_minus_pressed2() -> void:
	#if audio.value <= 20:
		#return
	#audio.value -= 20
	#GameManager.volume_audio -= db_to_percent_perceptual(audio.value)
	#set_bus_volume_percent("pl_btn", music.value)
#
#
#func _on_bg_finished() -> void:
	#$bg.play()

extends Control

@onready var minus: Button = $HSplitContainer/minus
@onready var music: ProgressBar = $HSplitContainer/music
@onready var plus: Button = $HSplitContainer/plus
@onready var minus1: Button = $HSplitContainer2/minus
@onready var audio: ProgressBar = $HSplitContainer2/audio
@onready var plus2: Button = $HSplitContainer2/plus

const MIN_DB := -80.0
const MAX_DB := 0.0 # recommandé 0 dB max pour éviter le clipping (mets 6.0 si tu veux autoriser +6 dB)

# Convertit un pourcentage en valeur dB
func percent_to_db_perceptual(pct: float) -> float:
	pct = clamp(pct, 0.0, 100.0)
	var a_min = db_to_linear(MIN_DB)   # ~0.0001
	var a_max = db_to_linear(MAX_DB)   # 1.0 si 0 dB, ~1.995 si 6 dB
	var a = lerp(a_min, a_max, pct / 100.0)
	return linear_to_db(a)

# Convertit une valeur dB en pourcentage
func db_to_percent_perceptual(db: float) -> float:
	var a_min := db_to_linear(MIN_DB)
	var a_max := db_to_linear(MAX_DB)
	var a := db_to_linear(db)
	return clamp(inverse_lerp(a_min, a_max, a) * 100.0, 0.0, 100.0)

func _ready() -> void:
	# Récupérer les volumes stockés dans GameManager
	var music_percent = db_to_percent_perceptual(GameManager.volume_music)
	var audio_percent = db_to_percent_perceptual(GameManager.volume_audio)
	
	# Mettre à jour les barres de progression
	music.value = music_percent
	audio.value = audio_percent
	
	# Appliquer les volumes aux bus audio
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("BG_music"), GameManager.volume_music)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("pl_btn"), GameManager.volume_audio)
	
	print("Valeur initiale music: ", music.value)
	print("Volume music en dB: ", GameManager.volume_music)

func _on_minus_pressed() -> void:
	$btn.play()
	# Réduire de 10 points de pourcentage, pas en dessous de 0
	music.value = max(music.value - 10, 0)
	
	# Convertir le nouveau pourcentage en dB et l'appliquer
	var db_value = percent_to_db_perceptual(music.value)
	GameManager.volume_music = db_value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("BG_music"), db_value)
	
	print("Nouveau volume music: ", music.value, "%, ", db_value, " dB")

func _on_plus_pressed() -> void:
	$btn.play()
	# Augmenter de 10 points de pourcentage, pas au-dessus de 100
	music.value = min(music.value + 10, 100)
	
	# Convertir le nouveau pourcentage en dB et l'appliquer
	var db_value = percent_to_db_perceptual(music.value)
	GameManager.volume_music = db_value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("BG_music"), db_value)
	
	print("Nouveau volume music: ", music.value, "%, ", db_value, " dB")

func _on_minus_pressed2() -> void:
	$btn.play()
	# Réduire de 10 points de pourcentage, pas en dessous de 0
	audio.value = max(audio.value - 10, 0)
	
	# Convertir le nouveau pourcentage en dB et l'appliquer
	var db_value = percent_to_db_perceptual(audio.value)
	GameManager.volume_audio = db_value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("pl_btn"), db_value)
	
	print("Nouveau volume audio: ", audio.value, "%, ", db_value, " dB")

func _on_plus_pressed2() -> void:
	$btn.play()
	# Augmenter de 10 points de pourcentage, pas au-dessus de 100
	audio.value = min(audio.value + 10, 100)
	
	# Convertir le nouveau pourcentage en dB et l'appliquer
	var db_value = percent_to_db_perceptual(audio.value)
	GameManager.volume_audio = db_value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("pl_btn"), db_value)
	
	print("Nouveau volume audio: ", audio.value, "%, ", db_value, " dB")

func _on_bg_finished() -> void:
	$bg.play()
