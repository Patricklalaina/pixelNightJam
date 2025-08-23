extends CharacterBody2D

# Vitesse de déplacement
@export var speed: float = 120.0
# Distance maximale de détection
@export var vision_range: float = 220.0
# Points de patrouille (NodePath vers des Node2D/Marker2D/Position2D)
@export var patrol_points: Array[NodePath] = []
# Utiliser NavigationAgent2D si présent (ajoutez un enfant NavigationAgent2D)
@export var use_navigation: bool = false

var player: Node2D = null
var _targets: Array[Node2D] = []
var _current_target: Node2D = null
var _rng := RandomNumberGenerator.new()
var _nav: NavigationAgent2D = null

func _ready() -> void:
	_rng.randomize()
	# Récupérer player (par nom "player" ou groupe "Player")
	player = _find_player()
	# Résoudre les points de patrouille
	for p in patrol_points:
		var n := get_node_or_null(p)
		if n and n is Node2D:
			_targets.append(n)
	_pick_new_patrol_target()

	# Option navigation
	if use_navigation and has_node("NavigationAgent2D"):
		_nav = $NavigationAgent2D
		if _current_target:
			_nav.target_position = _current_target.global_position

func _physics_process(delta: float) -> void:
	if GameManager.gameOver:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# 1) Détection du joueur
	if player and _can_see_player(player):
		if _is_player_hidden():
			# Joueur caché -> on repart sur une autre cible de patrouille
			_pick_new_patrol_target()
		else:
			# Joueur visible -> partie terminée
			GameManager.lose_game()
			return

	# 2) Patrouille vers la cible courante
	_move_towards_target(delta)

func _move_towards_target(delta: float) -> void:
	if _current_target == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var target_pos := _current_target.global_position
	var dir := Vector2.ZERO

	if _nav:
		# Navigation (si NavigationRegion2D existe dans la scène)
		_nav.target_position = target_pos
		var next_pos := _nav.get_next_path_position()
		dir = (next_pos - global_position).normalized()
	else:
		dir = (target_pos - global_position).normalized()

	velocity = dir * speed
	move_and_slide()

	# Arrivé proche -> choisir une nouvelle cible
	if global_position.distance_to(target_pos) <= 8.0:
		_pick_new_patrol_target()

func _pick_new_patrol_target() -> void:
	if _targets.is_empty():
		_current_target = null
		return
	_current_target = _targets[_rng.randi_range(0, _targets.size() - 1)]

func _can_see_player(p: Node2D) -> bool:
	# Distance
	var dist := global_position.distance_to(p.global_position)
	if dist > vision_range:
		return false

	# Ligne de vue (raycast) bloquée par les murs/colliders
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(global_position, p.global_position)
	query.exclude = [self]
	# Le joueur a un collider: si le raycast touche d'abord un mur, pas de vue
	var res := space_state.intersect_ray(query)
	if res.is_empty():
		# Rien touché (rare) -> pas de vue fiable
		return false
	return res.get("collider") == p

func _is_player_hidden() -> bool:
	# Le joueur est "caché" si non visible côté GameManager (show == false)
	# ou si la séquence de cachette est en place et l’anim de hide a fini.
	if GameManager.show == false:
		return true
	if GameManager.hidePL and GameManager.hideAnimationOK:
		return true
	return false

func _find_player() -> Node2D:
	# 1) Groupe "Player" si défini
	var g := get_tree().get_nodes_in_group("Player")
	if g.size() > 0 and g[0] is Node2D:
		return g[0]
	# 2) Recherche par nom "player"
	var n := get_tree().get_root().find_child("player", true, false)
	if n and n is Node2D:
		return n
	return null
