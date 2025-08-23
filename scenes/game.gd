extends Node2D

func _process(delta: float) -> void:
	if GameManager.hideAnimationOK:
		if GameManager.hidePL:
			$player.visible = false
			GameManager.show = false
	if GameManager.timeOut:
		$player.visible = true
		GameManager.show = true
