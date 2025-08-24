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
# IMPORTANT: Assure-toi que 'Walls' est bien coché ici (et éventuellement 'Player').
@export_flags_2d_physics var los_collision_mask: int = 1
# Visibilité entre waypoints (coche uniquement Walls)
@export_flags_2d_physics var nav_collision_mask: int = 1

# Anti-jitter
@export var steer_cooldown_time: float = 0.25
@export var stuck_distance_epsilon: float = 0.6
@export var stuck_time_threshold: float = 0.3

# Kill à proximité: distance et options
@export var kill_distance: float = 32.0
@export var require_line_of_sight_for_kill: bool = true
@export var respect_player_hidden: bool = true

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D as AnimatedSprite2D
@onready var detection_area: Area2D = get_node_or_null("DetectionArea") as Area2D
@onready var detection_shape: CollisionShape2D = (detection_area.get_node_or_null("CollisionShape2D") as CollisionShape2D) if detection_area else null
# Optionnel: une petite Area2D dédiée à l'impact si présente
@onready var kill_area: Area2D = get_node_or_null("KillArea") as Area2D

var _player: Node2D = null
var _player_in_radius: bool = false
var _waypoint_nodes: Array[Node2D] = []
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

func _ready() -> void:
	if anim:
		anim.play("idle")

	if detection_shape and detection_shape.shape is CircleShape2D:
		var circle: CircleShape2D = detection_shape.shape as CircleShape2D
		circle.radius = detection_radius

	if detection_area:
		if not detection_area.body_entered.is_connected(_on_detection_body_entered):
			detection_area.body_entered.connect(_on_detection_body_entered)
		if not detection_area.body_exited.is_connected(_on_detection_body_exited):
			detection_area.body_exited.connect(_on_detection_body_exited)
		if not detection_area.area_entered.is_connected(_on_detection_area_entered):
			detection_area.area_entered.connect(_on_detection_area_entered)

	if kill_area:
		if not kill_area.body_entered.is_connected(_on_kill_area_entered):
			kill_area.body_entered.connect(_on_kill_area_entered)
		if not kill_area.area_entered.is_connected(_on_kill_area_area_entered):
			kill_area.area_entered.connect(_on_kill_area_area_entered)

	_refresh_player_ref()
	_load_waypoints()
	_build_waypoint_graph()
	_last_pos = global_position

func _physics_process(delta: float) -> void:
	if _game_over_triggered:
		return

	if _steer_cooldown > 0.0:
		_steer_cooldown = max(0.0, _steer_cooldown - delta)

	if _player == null or not is_instance_valid(_player):
		_refresh_player_ref()

	# Poursuite si: dans zone + LOS dégagée ET joueur pas "caché" (si respect_player_hidden)
	var sees_player := _player_in_radius and _player != null and _has_line_of_sight()
	var hidden_block := respect_player_hidden and _is_player_hidden()
	var should_chase: bool = sees_player and not hidden_block

	if should_chase:
		_set_velocity_chase(delta)
	else:
		_set_velocity_patrol(delta)

	var intended_move: bool = velocity.length() > 0.05
	move_and_slide()

	# Déblocage
	var moved: float = (global_position - _last_pos).length()
	if intended_move:
		_stuck_time = _stuck_time + get_process_delta_time() if moved < stuck_distance_epsilon else 0.0
	else:
		_stuck_time = 0.0

	if _stuck_time >= stuck_time_threshold:
		_steer_sign = -_steer_sign
		_steer_cooldown = steer_cooldown_time
		if not should_chase:
			if not _recompute_subtarget():
				_advance_wp()
				_recompute_subtarget()
		velocity = Vector2.ZERO
		_stuck_time = 0.0

	# 1) Collision physique durant le slide
	_check_player_collision()

	# 2) Kill par proximité indépendante du mouvement et du radius
	_check_proximity_kill()

	_update_move_anim()
	_last_pos = global_position

func _set_velocity_chase(delta: float) -> void:
	if _player == null:
		velocity = Vector2.ZERO
		return
	var to_player: Vector2 = _player.global_position - global_position
	if to_player.length() <= 0.001:
		velocity = Vector2.ZERO
		return
	var dir: Vector2 = to_player.normalized()
	velocity = _avoid_walls(dir, delta) * speed

func _set_velocity_patrol(delta: float) -> void:
	if _waypoint_nodes.is_empty():
		velocity = Vector2.ZERO
		return

	_prune_invalid_waypoints()
	if _waypoint_nodes.is_empty():
		velocity = Vector2.ZERO
		return

	var target_reached: bool = false
	if _subtarget_id == -1:
		target_reached = _recompute_subtarget()

	if _subtarget_id != -1 and _wp_astar.has_point(_subtarget_id):
		var sub_pos: Vector2 = _waypoint_nodes[_subtarget_id].global_position
		var to_sub: Vector2 = sub_pos - global_position
		if to_sub.length() <= waypoint_tolerance:
			target_reached = _recompute_subtarget()
			if target_reached:
				_advance_wp()
				_recompute_subtarget()

	if _subtarget_id != -1 and _wp_astar.has_point(_subtarget_id):
		var sub_pos2: Vector2 = _waypoint_nodes[_subtarget_id].global_position
		var dir: Vector2 = (sub_pos2 - global_position).normalized()
		velocity = _avoid_walls(dir, delta) * speed
	else:
		velocity = Vector2.ZERO

func _advance_wp() -> void:
	if _waypoint_nodes.is_empty():
		return
	_wp_index += 1
	if _wp_index >= _waypoint_nodes.size():
		_wp_index = 0 if loop_patrol else _waypoint_nodes.size() - 1

func _avoid_walls(base_dir: Vector2, delta: float) -> Vector2:
	if base_dir == Vector2.ZERO:
		return base_dir

	var motion: Vector2 = base_dir * speed * delta
	if not test_move(global_transform, motion):
		return base_dir

	var primary_sign: int = _steer_sign
	var angles: Array[int] = [15, 30, 45, 60, 90, 120, 150, 180]

	for a in angles:
		var d1: Vector2 = base_dir.rotated(deg_to_rad(primary_sign * a))
		motion = d1 * speed * delta
		if not test_move(global_transform, motion):
			if _steer_cooldown <= 0.0:
				_steer_cooldown = steer_cooldown_time
			return d1

		var d2: Vector2 = base_dir.rotated(deg_to_rad(-primary_sign * a))
		motion = d2 * speed * delta
		if not test_move(global_transform, motion):
			if _steer_cooldown <= 0.0:
				_steer_cooldown = steer_cooldown_time
			return d2

	return Vector2.ZERO

func _has_line_of_sight() -> bool:
	if _player == null:
		return false
	var from: Vector2 = global_position
	var to: Vector2 = _player.global_position
	if from == to:
		return true

	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var params: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(from, to)
	params.collision_mask = los_collision_mask

	var exclude: Array[RID] = []
	exclude.append(self.get_rid())
	if detection_area:
		exclude.append(detection_area.get_rid())
	params.exclude = exclude

	var hit: Dictionary = space.intersect_ray(params)
	if hit.is_empty():
		# rien entre nous -> LOS OK
		return true
	var collider: Object = hit.get("collider")
	# Si le premier hit est le joueur -> LOS OK
	return collider == _player or _is_player_node(collider)

func _check_player_collision() -> void:
	for i in range(get_slide_collision_count()):
		var c: KinematicCollision2D = get_slide_collision(i)
		var col: Object = c.get_collider()
		if col == null:
			continue
		if col == _player or _is_player_node(col):
			if not _game_over_triggered:
				# On respecte ici aussi le mur et le "caché" si demandé
				if (not require_line_of_sight_for_kill or _has_line_of_sight()) and (not respect_player_hidden or not _is_player_hidden()):
					_trigger_game_over()
					return

func _check_proximity_kill() -> void:
	if _game_over_triggered or _player == null or not is_instance_valid(_player):
		return
	# Distance brute
	if global_position.distance_squared_to(_player.global_position) <= kill_distance * kill_distance:
		# Respecte mur et "caché" selon options
		if (not require_line_of_sight_for_kill or _has_line_of_sight()) and (not respect_player_hidden or not _is_player_hidden()):
			_trigger_game_over()

func _update_move_anim() -> void:
	if anim == null:
		return
	if velocity.length() < 1.0:
		anim.play("idle")
		return
	if abs(velocity.x) > abs(velocity.y):
		anim.play("right" if velocity.x > 0.0 else "left")
	else:
		anim.play("down" if velocity.y > 0.0 else "up")

func _on_detection_body_entered(body: Node) -> void:
	if body == null:
		return
	# Cette zone sert seulement à activer la poursuite
	if _is_player_node(body):
		# Si on respecte l'état "caché", ignorer l'entrée si le joueur est caché
		if respect_player_hidden and _is_player_hidden():
			return
		_player_in_radius = true
		if _player == null and body is Node2D:
			_player = body as Node2D

func _on_detection_body_exited(body: Node) -> void:
	if _is_player_node(body):
		_player_in_radius = false

func _on_detection_area_entered(area: Area2D) -> void:
	if area and _is_player_node(area):
		# Si on respecte l'état "caché", ignorer l'entrée si le joueur est caché
		if respect_player_hidden and _is_player_hidden():
			return
		_player_in_radius = true
		var owner_node := area.get_owner()
		if _player == null and owner_node and owner_node is Node2D:
			_player = owner_node as Node2D

func _on_kill_area_entered(obj: Node) -> void:
	if obj and _is_player_node(obj) and not _game_over_triggered:
		if (not require_line_of_sight_for_kill or _has_line_of_sight()) and (not respect_player_hidden or not _is_player_hidden()):
			_trigger_game_over()

func _on_kill_area_area_entered(area: Area2D) -> void:
	if area and _is_player_node(area) and not _game_over_triggered:
		if (not require_line_of_sight_for_kill or _has_line_of_sight()) and (not respect_player_hidden or not _is_player_hidden()):
			_trigger_game_over()

func _refresh_player_ref() -> void:
	if player_path != NodePath():
		_player = get_node_or_null(player_path) as Node2D
	if _player == null:
		var n1: Node = get_tree().get_first_node_in_group("Player")
		if n1 == null:
			n1 = get_tree().get_first_node_in_group("player")
		if n1 and n1 is Node2D:
			_player = n1 as Node2D
	if _player == null:
		var n2: Node = get_tree().get_root().find_child("player", true, false)
		if n2 == null:
			n2 = get_tree().get_root().find_child("Player", true, false)
		if n2 and n2 is Node2D:
			_player = n2 as Node2D

func _load_waypoints() -> void:
	_waypoint_nodes.clear()

	var parent_node: Node = get_parent()
	if parent_node:
		_gather_points_by_sequence(parent_node, _waypoint_nodes)

	if _waypoint_nodes.is_empty():
		for p in waypoints:
			var n2d: Node2D = get_node_or_null(p) as Node2D
			if n2d:
				_waypoint_nodes.append(n2d)

	if _waypoint_nodes.is_empty():
		var container: Node = null
		if patrol_container_path != NodePath():
			container = get_node_or_null(patrol_container_path)
		for node in get_tree().get_nodes_in_group("enemy_patrol"):
			if node is Node2D:
				var n2d2: Node2D = node as Node2D
				if container == null or (container is Node and (container as Node).is_ancestor_of(n2d2)):
					_waypoint_nodes.append(n2d2)

		_waypoint_nodes.sort_custom(func(a: Node2D, b: Node2D) -> bool:
			var an: String = a.name
			var bn: String = b.name
			var ai: int = _extract_trailing_int_from_string(an)
			var bi: int = _extract_trailing_int_from_string(bn)
			return ai < bi if (ai != -1 and bi != -1) else (an.naturalnocasecmp_to(bn) < 0)
		)

	if _waypoint_nodes.size() > 0:
		_wp_index = clamp(_wp_index, 0, _waypoint_nodes.size() - 1)
	else:
		_wp_index = 0

func _build_waypoint_graph() -> void:
	_wp_astar = AStar2D.new()
	for i in range(_waypoint_nodes.size()):
		var pos: Vector2 = _waypoint_nodes[i].global_position
		_wp_astar.add_point(i, pos)
	for i in range(_waypoint_nodes.size()):
		for j in range(i + 1, _waypoint_nodes.size()):
			var a: Vector2 = _waypoint_nodes[i].global_position
			var b: Vector2 = _waypoint_nodes[j].global_position
			if _is_clear_path(a, b):
				_wp_astar.connect_points(i, j, true)

func _is_clear_path(a: Vector2, b: Vector2) -> bool:
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var params: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(a, b)
	params.collision_mask = nav_collision_mask
	var hit: Dictionary = space.intersect_ray(params)
	return hit.is_empty()

func _find_nearest_waypoint_id(pos: Vector2) -> int:
	var best_id: int = -1
	var best_d2: float = INF
	for i in range(_waypoint_nodes.size()):
		var d2: float = pos.distance_squared_to(_waypoint_nodes[i].global_position)
		if d2 < best_d2:
			best_d2 = d2
			best_id = i
	return best_id

func _recompute_subtarget() -> bool:
	if _waypoint_nodes.is_empty():
		_subtarget_id = -1
		return false

	var start_id: int = _find_nearest_waypoint_id(global_position)
	if start_id == -1:
		_subtarget_id = -1
		return false

	var target_id: int = clamp(_wp_index, 0, _waypoint_nodes.size() - 1)
	var path: PackedInt64Array = _wp_astar.get_id_path(start_id, target_id)

	if path.size() == 0:
		var saved: int = target_id
		var tries: int = 0
		while tries < _waypoint_nodes.size():
			if loop_patrol:
				target_id = (target_id + 1) % _waypoint_nodes.size()
			else:
				target_id = min(target_id + 1, _waypoint_nodes.size() - 1)
			if target_id == saved:
				break
			path = _wp_astar.get_id_path(start_id, target_id)
			if path.size() > 0:
				_wp_index = target_id
				break
			tries += 1

	if path.size() == 0:
		_subtarget_id = -1
		return false

	if path.size() <= 1:
		_subtarget_id = -1
		return true

	_subtarget_id = int(path[1])
	return false

func _prune_invalid_waypoints() -> void:
	var cleaned: Array[Node2D] = []
	for n2d in _waypoint_nodes:
		if n2d != null and is_instance_valid(n2d):
			cleaned.append(n2d)
	_waypoint_nodes = cleaned
	if _wp_index >= _waypoint_nodes.size():
		_wp_index = max(0, _waypoint_nodes.size() - 1)

static func _extract_trailing_int_from_string(s: String) -> int:
	var i: int = s.length() - 1
	var digits: String = ""
	while i >= 0 and s[i] >= "0" and s[i] <= "9":
		digits = s[i] + digits
		i -= 1
	if digits.length() > 0:
		return int(digits)
	return -1

func _gather_points_by_sequence(root: Node, out: Array[Node2D]) -> void:
	var i: int = 1
	while true:
		var name1 := "point%d" % i
		var node := root.get_node_or_null(NodePath(name1))
		if node == null:
			var name2 := "Point%d" % i
			node = root.get_node_or_null(NodePath(name2))
		if node == null:
			break
		if node is Node2D:
			out.append(node as Node2D)
		else:
			push_warning("%s existe sous %s mais n'est pas un Node2D" % [node.name, root.get_path()])
		i += 1

func _is_player_node(o: Object) -> bool:
	if o == null:
		return false
	if o is Node:
		var n := o as Node
		if n.is_in_group("Player") or n.is_in_group("player"):
			return true
		var nm := n.name.to_lower()
		return nm == "player"
	return false

func _is_player_hidden() -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	# 1) Méthode dédiée
	if (_player as Object).has_method("is_hidden"):
		return (_player as Object).call("is_hidden")
	# 2) Propriété booléenne "hidden"
	if "hidden" in _player:
		var v = (_player as Node).get("hidden")
		if typeof(v) == TYPE_BOOL:
			return v
	# 3) CanvasItem.visible (Node2D hérite de CanvasItem)
	if _player is CanvasItem:
		return not (_player as CanvasItem).visible
	return false

func _trigger_game_over() -> void:
	_game_over_triggered = true
	set_physics_process(false)
	if GameManager and GameManager.has_method("record_game_result"):
		GameManager.record_game_result(GameManager.score, false)
	get_tree().change_scene_to_file("res://scenes/game_over.tscn")
