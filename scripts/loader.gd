extends Control

@onready var progress_bar: TextureProgressBar = $progress
@onready var percent: Label = $progress/percent

var path_scene: Array = ["res://scenes/menu.tscn", "res://scenes/setting.tscn", "res://scenes/help.tscn", "res://scenes/game.tscn"]
var current_index: int = 0
var loading_started: bool = false
var all_loaded: bool = false
var i: int = 0

func _ready():
	start_next_load()

func start_next_load():
	if current_index < path_scene.size():
		ResourceLoader.load_threaded_request(path_scene[current_index])
		loading_started = true
	else:
		all_loaded = true

func _process(delta: float) -> void:
	if all_loaded:
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
		return
	if i >= 50:
		if loading_started and current_index < path_scene.size():
			var progress: Array = [0.0]
			var status = ResourceLoader.load_threaded_get_status(path_scene[current_index], progress)
			
			# Calcul de la progression totale
			var total_progress = (float(current_index) + progress[0]) / float(path_scene.size())
			progress_bar.value = total_progress * 100
			percent.text = str(int(total_progress * 100)) + "%"
			
			if status == ResourceLoader.THREAD_LOAD_LOADED:
				current_index += 1
				loading_started = false
				start_next_load()
			elif status == ResourceLoader.THREAD_LOAD_FAILED:
				print("Erreur de chargement : ", path_scene[current_index])
				current_index += 1
				loading_started = false
				start_next_load()
		i = 0
	else:
		i += 1
