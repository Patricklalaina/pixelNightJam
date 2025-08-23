#extends CharacterBody2D
#
#@export var speed: float = 200.0
#@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
#
#var played: bool = false
#
#func _ready() -> void:
	#anim.play("idle")
	#$AnimationPlayer.animation_finished.connect(_on_anim_finished)
#
#func _on_anim_finished(anim_name: String) -> void:
	#print("Here/ato")
	#GameManager.hideAnimationOK = !GameManager.hideAnimationOK
		## Ici tu peux lancer une autre anim, ou mettre le joueur en invisible, etc.
#
#
#func _physics_process(delta: float) -> void:
	#if GameManager.timeOut:
		#$AnimationPlayer.play("maximize")
		#await $AnimationPlayer.animation_finished
		#GameManager.timeOut = false
	#if GameManager.hidePL == false:
		#played = false
		#handle_movement()
	#elif (GameManager.hidePL == true and not played):
		#$AnimationPlayer.play("minimize")
		#played = true
#
#func handle_movement():
	#var input_direction = Vector2.ZERO
#
	#if Input.is_action_pressed("ui_up"):
		#input_direction.y -= 1
	#if Input.is_action_pressed("ui_down"):
		#input_direction.y += 1
	#if Input.is_action_pressed("ui_left"):
		#input_direction.x -= 1
	#if Input.is_action_pressed("ui_right"):
		#input_direction.x += 1
	#
	#input_direction = input_direction.normalized()
	#velocity = input_direction * speed
	#move_and_slide()
	#
	## Gérer les animations
	#if input_direction != Vector2.ZERO:
		#if abs(input_direction.x) > abs(input_direction.y):
			## Gauche ou droite
			#if input_direction.x > 0:
				#anim.play("right")
			#else:
				#anim.play("left")
		#else:
			## Haut ou bas
			#if input_direction.y > 0:
				#anim.play("down")
			#else:
				#anim.play("up")
	#else:
		#anim.play("idle")


extends CharacterBody2D

@export var speed: float = 200.0
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var played: bool = false
var animationInProgress: bool = false

func _ready() -> void:
	anim.play("idle")
	$AnimationPlayer.animation_finished.connect(_on_anim_finished)

func _on_anim_finished(anim_name: String) -> void:
	print("Animation terminée: ", anim_name)
	animationInProgress = false
	
	if anim_name == "maximize":
		# Compléter toute la séquence après maximize
		GameManager.complete_sequence()
		visible = true
		anim.play("idle")
		print("Séquence complète - joueur remis en état normal")
	elif anim_name == "minimize":
		GameManager.hideAnimationOK = true
		print("Animation minimize terminée")

func _physics_process(delta: float) -> void:
	# Éviter de traiter plusieurs fois pendant les animations
	if animationInProgress:
		return
	
	# Gestion du maximize quand le timer se termine
	if GameManager.timeOut and GameManager.timerActive and not GameManager.isMaximizing:
		animationInProgress = true
		GameManager.isMaximizing = true
		visible = true
		$AnimationPlayer.play("maximize")
		print("Démarrage animation maximize")
		return
	
	# Gestion normale du joueur
	if not GameManager.isMaximizing and not animationInProgress:
		if GameManager.hidePL == false:
			played = false
			handle_movement()
		elif (GameManager.hidePL == true and not played):
			animationInProgress = true
			$AnimationPlayer.play("minimize")
			played = true
			print("Démarrage animation minimize")

func handle_movement():
	var input_direction = Vector2.ZERO

	if Input.is_action_pressed("ui_up"):
		input_direction.y -= 1
	if Input.is_action_pressed("ui_down"):
		input_direction.y += 1
	if Input.is_action_pressed("ui_left"):
		input_direction.x -= 1
	if Input.is_action_pressed("ui_right"):
		input_direction.x += 1
	
	input_direction = input_direction.normalized()
	velocity = input_direction * speed
	move_and_slide()
	
	# Gérer les animations
	if input_direction != Vector2.ZERO:
		if abs(input_direction.x) > abs(input_direction.y):
			if input_direction.x > 0:
				anim.play("right")
			else:
				anim.play("left")
		else:
			if input_direction.y > 0:
				anim.play("down")
			else:
				anim.play("up")
	else:
		anim.play("idle")
