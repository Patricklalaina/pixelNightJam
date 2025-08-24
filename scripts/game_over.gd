extends Control

func _ready() -> void:
	$Panel/VBoxContainer/Retry.grab_focus()

func _on_retry_pressed() -> void:
	await GameManager._play_msc($click)
	# Recharge la scène de jeu
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_menu_pressed() -> void:
	await GameManager._play_msc($click)
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
