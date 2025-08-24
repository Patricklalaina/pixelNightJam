extends CharacterBody2D
class_name Enemy

@export var speed: float = 150.0
@export_node_path("Node2D") var player_path: NodePath
@export var detection_radius: float = 160.0

# Patrouille
@export var waypoints: Array[NodePath] = []
@export_node_path("Node2D") var patrol_container_path: NodePath
@export var waypoint_tolerance: float = 8.0
@export var loop_patrol: bool = true

# Ligne de vue vers le joueur (coche Walls + Player)
@export_flags_2d_physics var los_collision_mask: int = 1
# Visibilité entre waypoints (coche uniquement Walls)
@export_flags_2d_physics var nav_collision_mask: int = 1

# Anti-jitter
@export var steer_cooldown_time: float = 0.25
@export var stuck_distance_epsilon: float = 0.6

var _wp_index: int = 0
var _game_over_triggered: bool = false

# Etat anti-oscillation / déblocage
var _steer_sign: int = 1
var _steer_cooldown: float = 0.0
var _last_pos: Vector2 = Vector2.ZERO
var _stuck_time: float = 0.0

# Graphe de patrouille (A* sur waypoints)
var _wp_astar: AStar2D = AStar2D.new()
var _subtarget_id: int = -1  # prochain waypoint intermédiaire (id dans AStar), -1 si aucun

# ... (le reste de votre script inchangé)

func _trigger_game_over() -> void:
	_game_over_triggered = true
	set_physics_process(false)
	# Marquer la raison: attrapé par un ennemi (pas un timeout)
	if GameManager:
		GameManager.last_end_by_timeout = false
	# Enregistrer et changer de scène
	if GameManager and GameManager.has_method("record_game_result"):
		GameManager.record_game_result(GameManager.score, false)
	get_tree().change_scene_to_file("res://scenes/game_over.tscn")
