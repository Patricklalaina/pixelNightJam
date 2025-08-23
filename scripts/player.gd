extends CharacterBody2D

@export var speed: float = 200.0
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var played: bool = false

func _ready() -> void:
	anim.play("idle")
	$AnimationPlayer.animation_finished.connect(_on_anim_finished)

func _on_anim_finished(anim_name: String) -> void:
	print("Here/ato")
	GameManager.hideAnimationOK = !GameManager.hideAnimationOK
		# Ici tu peux lancer une autre anim, ou mettre le joueur en invisible, etc.


func _physics_process(delta: float) -> void:
	if GameManager.timeOut:
		$AnimationPlayer.play("maximize")
		await $AnimationPlayer.animation_finished
		GameManager.timeOut = false
	if GameManager.hidePL == false:
		played = false
		handle_movement()
	elif (GameManager.hidePL == true and not played):
		$AnimationPlayer.play("minimize")
		played = true

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
			# Gauche ou droite
			if input_direction.x > 0:
				anim.play("right")
			else:
				anim.play("left")
		else:
			# Haut ou bas
			if input_direction.y > 0:
				anim.play("down")
			else:
				anim.play("up")
	else:
		anim.play("idle")
