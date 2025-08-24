extends Node2D

var _enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()

	# Nouveau run -> reset (score 0, level 1). Transition de niveau -> pas de reset.
	if GameManager.new_run:
		GameManager.start_new_game()

	# Connecte pour mettre à jour timer, UI et (re)spawn à chaque changement de niveau
	if not GameManager.level_changed.is_connected(_on_level_changed):
		GameManager.level_changed.connect(_on_level_changed)

	# Mise à jour UI niveau + spawn selon le niveau courant
	_update_level_ui()
	_clear_existing_enemies()
	_spawn_enemies_for_current_level()

	# Démarre le timer du HUD avec la durée du niveau courant
	var level_hud = $Control/HUD
	if level_hud and not level_hud.level_timeout.is_connected(_on_level_timeout):
		level_hud.level_timeout.connect(_on_level_timeout)
	if level_hud:
		level_hud.start_level_timer(GameManager.get_level_time())

func _on_level_changed(level: int, quota: int, time_limit: float) -> void:
	# UPDATE UI + respawn ennemis + redémarre timer
	_update_level_ui()
	_clear_existing_enemies()
	_spawn_enemies_for_current_level()
	var level_hud = $Control/HUD
	if level_hud:
		level_hud.start_level_timer(time_limit)

func _process(delta: float) -> void:
	if not GameManager.isMaximizing:
		if GameManager.hideAnimationOK and GameManager.hidePL:
			$player.visible = false
			GameManager.show = false
		elif not GameManager.hidePL:
			$player.visible = true
			GameManager.show = true

func _update_level_ui() -> void:
	var n := get_node_or_null("level")
	if n == null:
		n = find_child("level", true, false)
	if n and n is Label:
		(n as Label).text = "LEVEL " + str(GameManager.level)

func _clear_existing_enemies() -> void:
	var to_free: Array[Node] = []
	_collect_enemies_recursive(get_tree().current_scene, to_free)
	for e in to_free:
		if e and is_instance_valid(e):
			e.queue_free()

func _collect_enemies_recursive(node: Node, out: Array[Node]) -> void:
	if node == null:
		return
	# Détection via class_name Enemy (défini dans scripts/enemy.gd)
	if node is Enemy:
		out.append(node)
	for c in node.get_children():
		if c is Node:
			_collect_enemies_recursive(c, out)

func _spawn_enemies_for_current_level() -> void:
	var wanted = max(1, GameManager.level)  # N ennemis au niveau N
	var spawns := _gather_spawn_points()
	if spawns.is_empty():
		push_warning("Aucun 'pointN' trouvé pour spawn des ennemis.")
		return
	spawns.shuffle()
	var parent := _find_waypoint_container()
	if parent == null:
		parent = self

	for i in range(wanted):
		var e := _enemy_scene.instantiate()
		if e == null:
			continue
		parent.add_child(e)
		if e is Node2D:
			var pos := spawns[i % spawns.size()]
			(e as Node2D).global_position = pos

func _find_waypoint_container() -> Node:
	var root := get_tree().current_scene
	if root == null:
		return null
	var queue: Array[Node] = [root]
	while not queue.is_empty():
		var n: Node = queue.pop_front()
		if _has_seq_point_child(n):
			return n
		for c in n.get_children():
			if c is Node:
				queue.append(c)
	return null

func _has_seq_point_child(n: Node) -> bool:
	if n == null:
		return false
	var name1 := "point1"
	var name2 := "Point1"
	return n.get_node_or_null(NodePath(name1)) != null or n.get_node_or_null(NodePath(name2)) != null

func _gather_spawn_points() -> Array[Vector2]:
	var points: Array[Vector2] = []
	var container := _find_waypoint_container()
	if container == null:
		return points
	var i := 1
	while true:
		var name1 := "point%d" % i
		var name2 := "Point%d" % i
		var node := container.get_node_or_null(NodePath(name1))
		if node == null:
			node = container.get_node_or_null(NodePath(name2))
		if node == null:
			break
		if node is Node2D:
			points.append((node as Node2D).global_position)
		i += 1
	return points

func _on_level_timeout() -> void:
	# Si quota atteint à l'expiration -> transition de niveau, sinon Game Over
	if GameManager.has_met_quota():
		GameManager.perform_level_up_transition()
	else:
		if GameManager and GameManager.has_method("record_game_result"):
			GameManager.record_game_result(GameManager.score, false)
		get_tree().change_scene_to_file("res://scenes/game_over.tscn")

func _on_music_game_finished() -> void:
	$music_game.play()
