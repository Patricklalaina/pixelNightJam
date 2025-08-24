extends Control

func _ready() -> void:
	await get_tree().process_frame

	# Affiche "Timeout" si la fin de jeu vient du timer
	if GameManager.last_end_by_timeout:
		var title_label := get_node_or_null("ColorRect/VBoxContainer/Title") as Label
		if title_label:
			title_label.text = "Timeout"
		else:
			# Crée un titre en tête si la scène n'en expose pas
			var root_box := get_node_or_null("ColorRect/VBoxContainer") as VBoxContainer
			if root_box:
				var lbl := Label.new()
				lbl.name = "Title"
				lbl.text = "Timeout"
				lbl.add_theme_font_size_override("font_size", 36)
				lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				root_box.add_child(lbl)
				root_box.move_child(lbl, 0)

	# Focus "Rejouer" si présent
	var retry_btn := get_node_or_null("ColorRect/VBoxContainer/Buttons/Retry") as Button
	if retry_btn:
		retry_btn.grab_focus()

	# Abonnement aux mises à jour de stats
	if not GameManager.stats_updated.is_connected(_on_stats_updated):
		GameManager.stats_updated.connect(_on_stats_updated)

	# Titre des stats (séparé du corps)
	var stats_title := get_node_or_null("ColorRect/VBoxContainer/StatsTitle") as Label
	if stats_title:
		stats_title.text = "Historique des parties"
		stats_title.add_theme_font_size_override("font_size", 30)

	# Remplir la liste
	_populate_stats_list()

func _on_stats_updated() -> void:
	_populate_stats_list()

func _populate_stats_list() -> void:
	var content := get_node_or_null("ColorRect/VBoxContainer/StatsCenter/Scroll/Content") as VBoxContainer
	if content == null:
		return

	# S'assure que le contenu s'étire à la largeur du viewport du Scroll
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Nettoyage
	for child in content.get_children():
		child.queue_free()

	# Pas de stats
	if GameManager.stats.is_empty():
		var empty := Label.new()
		empty.text = "Aucune partie enregistrée."
		empty.modulate = Color(0.6, 0.6, 0.6)
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_child(empty)
		return

	# Une ligne par partie
	for i in range(GameManager.stats.size()):
		var e := GameManager.stats[i] as Dictionary
		var num := str(i + 1).pad_zeros(2)
		var won := bool(e.get("won", false))
		var res := "Win" if won else "Game Over"
		var score_txt := str(int(e.get("score", 0)))
		var date_txt := String(e.get("date", ""))

		var lbl := Label.new()
		lbl.text = "Partie %s — %s — %s pts — %s" % [num, res, score_txt, date_txt]
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.modulate = Color(0.6, 0.6, 0.6)
		content.add_child(lbl)

func _on_retry_pressed() -> void:
	var click := $click
	if click:
		await GameManager._play_msc(click)
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_menu_pressed() -> void:
	var click := $click
	if click:
		await GameManager._play_msc(click)
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
