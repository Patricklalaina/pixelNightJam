extends Control

func _ready() -> void:
	await get_tree().process_frame

	# Bouton de continuation
	var retry_btn := get_node_or_null("ColorRect/VBoxContainer/Buttons/Retry") as Button
	if retry_btn:
		retry_btn.text = "Continuer"
		retry_btn.grab_focus()

	# Titre: félicitations niveau passé
	var stats_title := get_node_or_null("ColorRect/VBoxContainer/StatsTitle") as Label
	if stats_title:
		var passed = max(1, GameManager.last_passed_level)
		stats_title.text = "Bravo ! Niveau %d passé 🎉".format([passed])
		stats_title.add_theme_font_size_override("font_size", 30)

	# Corps: prochain objectif
	var content := get_node_or_null("ColorRect/VBoxContainer/StatsCenter/Scroll/Content") as VBoxContainer
	if content:
		for child in content.get_children():
			child.queue_free()

		var next_level := GameManager.level
		var quota := GameManager.get_level_quota_current()
		var lbl := Label.new()
		lbl.text = "Prochain objectif: atteindre %d pts au niveau %d.\nScore actuel: %d".format([quota, next_level, GameManager.score])
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_child(lbl)

func _on_stats_updated() -> void:
	# Non utilisé pour l'écran de transition
	pass

func _on_retry_pressed() -> void:
	var click := $click
	if click:
		await GameManager._play_msc(click)
	# Retour jeu (ne reset pas le score)
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_menu_pressed() -> void:
	var click := $click
	if click:
		await GameManager._play_msc(click)
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
