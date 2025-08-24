extends Area2D
class_name Collectible

@export var value: int = 1
@export var auto_rotate: bool = true
@export var rotate_speed_deg: float = 90.0
@export var pickup_vfx: PackedScene
@export var pickup_sound: AudioStream

@onready var _audio: AudioStreamPlayer2D = $PickupSound as AudioStreamPlayer2D
@onready var _shape: CollisionShape2D = $CollisionShape2D as CollisionShape2D
@onready var _sprite: Node2D = get_node_or_null("Sprite2D") as Node2D

var _picked: bool = false

func _ready() -> void:
	# S'assure que l'Area détecte le joueur
	monitoring = true
	monitorable = true
	body_entered.connect(_on_body_entered)
	$Sprite2D.play("normal")


func _on_body_entered(body: Node) -> void:
	if _picked:
		return
	# Détecte le joueur par groupe "player" ou par nom "player"
	var is_player: bool = (body.name == "player") or body.is_in_group("player")
	if not is_player:
		return
	_pick()

func _pick() -> void:
	if _picked:
		return
	_picked = true

	# Désactive proprement pendant le flush des queries
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	if _shape:
		_shape.set_deferred("disabled", true)
	if _sprite:
		_sprite.visible = false

	# Score via GameManager (autoload)
	if "add_score" in GameManager:
		GameManager.add_score(value)

	# VFX optionnel
	if pickup_vfx:
		var vfx := pickup_vfx.instantiate()
		if vfx is Node2D:
			get_tree().current_scene.add_child(vfx)
			(vfx as Node2D).global_position = global_position

	# Joue le son déjà assigné sur le node AudioStreamPlayer2D
	var played := false
	if _audio:
		if _audio.playing:
			_audio.stop()
		if _audio.stream != null:
			_audio.play()
			played = true

	if played:
		await _audio.finished
