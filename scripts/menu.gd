extends Control

@onready var verification: Control = $verif_container

func _ready() -> void:
	verification.visible = false

func _quit_pressed() -> void:
	verification.visible = true

func _on_yes_pressed() -> void:
	get_tree().quit()

func _on_no_pressed() -> void:
	verification.visible = false

func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_setting_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/setting.tscn")

func _on_help_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/help.tscn")
