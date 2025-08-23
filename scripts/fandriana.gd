#extends Area2D
#
#func _ready() -> void:
	#$"../TextureButton/AnimatedSprite2D".play("default")
	#$"../TextureButton".visible = false
	#$"../bed".play("normal")
	#$"../Node/ProgressBar".visible = false
	#GameManager.tmpOBJ = $"../bed"
	#
#func _on_body_entered(body: Node2D) -> void:
	#print(body.name)
	#if (body.name == "player"):
		#$"../TextureButton".visible = true
#
#func _on_body_exited(body: Node2D) -> void:
	#if (body.name == "player"):
		#$"../TextureButton".visible = false
#
#
#func _on_texture_button_pressed() -> void:
	#GameManager.hidePL = true
	#$"../TextureButton".visible = false
	#$"../bed".play("hide_pl")
	#print("Start timerrrrrrrrrrr")
	#$"../Node".start_timer()
	#$"../Node/ProgressBar".visible = true

extends Area2D

var timerNode
var buttonPressed: bool = false

func _ready() -> void:
	$"../TextureButton/AnimatedSprite2D".play("default")
	$"../TextureButton".visible = false
	$"../bed".play("normal")
	$"../Node/ProgressBar".visible = false
	GameManager.tmpOBJ = $"../bed"
	timerNode = $"../Node"
	
	# Connecter le signal de timeout du timer une seule fois
	if not $"../Node/Timer".timeout.is_connected(_on_timer_finished):
		$"../Node/Timer".timeout.connect(_on_timer_finished)
	
func _on_body_entered(body: Node2D) -> void:
	print(body.name)
	if (body.name == "player" and not buttonPressed):
		$"../TextureButton".visible = true

func _on_body_exited(body: Node2D) -> void:
	if (body.name == "player"):
		$"../TextureButton".visible = false

func _on_texture_button_pressed() -> void:
	await GameManager._play_msc($"../btn")
	if buttonPressed:  # Éviter les pressions multiples
		return
		
	buttonPressed = true
	print("Bouton pressé - démarrage séquence")
	
	# Démarrer la séquence complète
	GameManager.start_hiding_sequence()
	
	$"../TextureButton".visible = false
	$"../bed".play("hide_pl")
	print("Start timer")
	timerNode.start_timer()
	$"../Node/ProgressBar".visible = true

func _on_timer_finished():
	print("Timer fini dans fandriana.gd")
	$"../Node/ProgressBar".visible = false
	# Permettre une nouvelle utilisation après un délai
	await get_tree().create_timer(2.0).timeout
	buttonPressed = false
	print("Interaction à nouveau possible")

# Fonction pour réinitialiser complètement l'interaction
func reset_interaction():
	buttonPressed = false
	$"../TextureButton".visible = false
	$"../Node/ProgressBar".visible = false
	timerNode.stop_timer()
	GameManager.reset_player_state()
