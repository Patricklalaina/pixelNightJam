extends Area2D

func _ready() -> void:
	$"../TextureButton/AnimatedSprite2D".play("default")
	$"../TextureButton".visible = false
	$"../bed".play("normal")
	$"../Node/ProgressBar".visible = false
	GameManager.tmpOBJ = $"../bed"
	
func _on_body_entered(body: Node2D) -> void:
	print(body.name)
	if (body.name == "player"):
		$"../TextureButton".visible = true

func _on_body_exited(body: Node2D) -> void:
	if (body.name == "player"):
		$"../TextureButton".visible = false


func _on_texture_button_pressed() -> void:
	GameManager.hidePL = true
	$"../TextureButton".visible = false
	$"../bed".play("hide_pl")
	print("Start timerrrrrrrrrrr")
	$"../Node".start_timer()
	$"../Node/ProgressBar".visible = true
