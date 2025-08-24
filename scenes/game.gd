extends Node2D

func _ready() -> void:
	# Réinitialise l'état de partie et le score à 0
	if "start_new_game" in GameManager:
		GameManager.start_new_game()

	# Récupère le node de timer de niveau (contenant Timer + Label) et démarre le compte
	var level_hud = $Control/HUD
	if level_hud and not level_hud.level_timeout.is_connected(_on_level_timeout):
		level_hud.level_timeout.connect(_on_level_timeout)
	# Démarre avec la durée définie dans le Timer du node (ou passe une durée: start_level_timer(90.0))
	if level_hud:
		level_hud.start_level_timer()

func _process(delta: float) -> void:
	# Gérer la visibilité seulement si pas en cours d'animation maximize
	if not GameManager.isMaximizing:
		if GameManager.hideAnimationOK and GameManager.hidePL:
			$player.visible = false
			GameManager.show = false
		elif not GameManager.hidePL:
			$player.visible = true
			GameManager.show = true

func _on_level_timeout() -> void:
	print("Victoire - fin du niveau (timer de niveau)")
	# Enregistrer la victoire et afficher l'écran de victoire avec les stats
	GameManager.record_game_result(GameManager.score, true)
	get_tree().change_scene_to_file("res://scenes/win.tscn")

func _on_music_game_finished() -> void:
	$music_game.play()
