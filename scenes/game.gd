extends Node2D

func _process(delta: float) -> void:
	# Gérer la visibilité seulement si pas en cours d'animation maximize
	if not GameManager.isMaximizing:
		if GameManager.hideAnimationOK and GameManager.hidePL:
			$player.visible = false
			GameManager.show = false
		elif not GameManager.hidePL:
			$player.visible = true
			GameManager.show = true


func _on_music_game_finished() -> void:
	$music_game.play()
