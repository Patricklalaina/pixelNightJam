extends Control


func _on_menu_pressed() -> void:
	await GameManager._play_msc($click)
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
