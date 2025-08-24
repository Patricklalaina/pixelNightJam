extends Control

@onready var label_2: Label = $Label2
@onready var progress_bar: TextureProgressBar = $progress
@onready var percent: Label = $progress/percent
var path_scene: Array = [
	"res://scenes/menu.tscn",
	"res://scenes/setting.tscn",
	"res://scenes/help.tscn",
	"res://scenes/game.tscn",
	"res://fonts/bulletin.regular.ttf",
	"res://fonts/born2bsporty-fs.regular.otf",
	"res://assets/Blank Top Down 16x16 Character Template.png", "res://assets/bonbon.png", "res://assets/enemy.png", "res://assets/power_up_sound_v2.ogg", "res://assets/progress1.png", "res://assets/progress2.png", "res://assets/sprite/armoire1.png", "res://assets/sprite/armoire2.png", "res://assets/sprite/back.svg", "res://assets/sprite/bg.wav", "res://assets/sprite/bonbon.png", "res://assets/sprite/click.wav", "res://assets/sprite/fandriana.png", "res://assets/sprite/frame.png", "res://assets/sprite/home_pack.png", "res://assets/sprite/lit_hide.png", "res://assets/sprite/plan.png", "res://assets/sprite/time.png", "res://assets/sprite/TopDownHouse_FloorsAndWalls.png", "res://assets/tapis.png",
	"res://scenes/armoire.tscn", "res://scenes/collectible.tscn", "res://scenes/collectible_spawner.tscn", "res://scenes/enemy.tscn", "res://scenes/game_over.tscn", "res://scenes/hud.tscn", "res://scenes/lit.tscn", "res://scenes/node.tscn", "res://scenes/player.tscn", "res://scenes/trano.tscn", "res://scenes/win.tscn"
]
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
	#if i >= 1:
	if loading_started and current_index < path_scene.size():
		var progress: Array = [0.0]
		label_2.text = "Load " + path_scene[current_index] + "..."
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
		#i = 0
	#else:
		#i += 1
