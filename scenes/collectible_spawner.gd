extends Node2D
# Pas de class_name pour éviter les collisions de classes globales

# Intervalle entre spawns (secondes)
@export var spawn_interval: float = 5.0
@export var start_on_ready: bool = true
@export var randomize_seed: bool = true

# Export du chemin de la scène collectible (modifiable depuis l’inspecteur)
@export_file("*.tscn") var collectible_scene_path: String = "res://scenes/collectible.tscn"
var collectible_scene: PackedScene = null

# Limites et règles
@export var max_active: int = 0                       # 0 = illimité
@export var allow_multiple_per_marker: bool = false   # false = 1 collectible max par Marker2D

# Durée de vie des collectibles (secondes). 0 = illimité
@export var collectible_lifetime: float = 5.0

# Sources possibles de markers (tous exportés)
@export var markers: Array[NodePath] = []                      # Option 1: liste directe
@export_node_path("Node") var marker_container_path: NodePath  # Option 2: conteneur
@export var marker_group: String = "collectible_marker"        # Option 3: groupe
@export var search_whole_scene_fallback: bool = true           # Option 4: scan global si rien trouvé

# Option 0: séquence de noms (marker2D, marker2D2, ..., marker2Dn)
@export var use_sequential_marker_names: bool = true
# Racine où se trouvent les markers séquentiels. Si vide, on utilisera 'marker_container_path' s'il est défini, sinon 'self'
@export_node_path("Node") var sequential_markers_root: NodePath = "."

# O$"../point1"ù instancier (sinon current_scene)
@export_node_path("Node") var spawn_parent_path: NodePath

# Spawns initiaux au _ready (facultatif)
@export var initial_spawn_count: int = 0

var _markers: Array[Marker2D] = []
var _occupied: Dictionary = {}   # Marker2D -> Array[Node]
var _active: Array[Node] = []
var _rng := RandomNumberGenerator.new()
var _timer: Timer

func _ready() -> void:
	_load_collectible_scene()
	_collect_markers()

	if randomize_seed:
		_rng.randomize()

	_timer = Timer.new()
	_timer.wait_time = max(0.05, spawn_interval)
	_timer.one_shot = false
	add_child(_timer)
	_timer.timeout.connect(_on_spawn_timeout)

	if initial_spawn_count > 0:
		spawn_now(initial_spawn_count)

	if start_on_ready:
		_timer.start()

func _load_collectible_scene() -> void:
	if collectible_scene_path.strip_edges() == "":
		collectible_scene = null
		return
	var res := load(collectible_scene_path)
	if res is PackedScene:
		collectible_scene = res
	else:
		collectible_scene = null
		push_warning("CollectibleSpawner: 'collectible_scene_path' ne pointe pas vers une PackedScene valide: " + collectible_scene_path)

func _on_spawn_timeout() -> void:
	spawn_now(1)

func spawn_now(count: int = 1) -> void:
	if collectible_scene == null:
		# Essaye de recharger si le chemin a été modifié en cours de route
		_load_collectible_scene()
		if collectible_scene == null:
			push_warning("CollectibleSpawner: collectible_scene est null (path: " + collectible_scene_path + ").")
			return

	if _markers.is_empty():
		_collect_markers()
		if _markers.is_empty():
			push_warning("CollectibleSpawner: aucun Marker2D trouvé.")
			return

	for i in range(count):
		if (max_active > 0) and (_active.size() >= max_active):
			return

		var candidates: Array[Marker2D] = []
		if allow_multiple_per_marker:
			candidates = _markers.duplicate()
		else:
			for m in _markers:
				if not _occupied.has(m) or (_occupied[m] as Array).is_empty():
					candidates.append(m)

		if candidates.is_empty():
			# Tous les markers sont occupés et multiples interdits
			return

		var idx := _rng.randi_range(0, candidates.size() - 1)
		var marker := candidates[idx]

		var inst := collectible_scene.instantiate()
		if inst == null:
			continue

		var parent: Node = get_node_or_null(spawn_parent_path) if (spawn_parent_path != NodePath()) else get_tree().current_scene
		if parent == null:
			parent = self

		parent.add_child(inst)

		# Positionner après add_child pour garantir un global_position correct
		if inst is Node2D:
			(inst as Node2D).global_position = marker.global_position

		# Programmer la durée de vie
		if collectible_lifetime > 0.0:
			var t := get_tree().create_timer(collectible_lifetime)  # SceneTreeTimer
			var weak = weakref(inst)
			t.timeout.connect(func():
				var obj = weak.get_ref()
				if obj and obj is Node and (obj as Node).is_inside_tree():
					(obj as Node).queue_free()
			, CONNECT_ONE_SHOT)

		# Suivi d'occupation et nettoyage à la suppression
		if not _occupied.has(marker):
			_occupied[marker] = []
		(_occupied[marker] as Array).append(inst)
		_active.append(inst)

		inst.tree_exited.connect(func():
			_active.erase(inst)
			if _occupied.has(marker):
				(_occupied[marker] as Array).erase(inst)
				if (_occupied[marker] as Array).is_empty():
					_occupied.erase(marker)
		, CONNECT_ONE_SHOT)

func start() -> void:
	if _timer:
		_timer.start()

func stop() -> void:
	if _timer:
		_timer.stop()

func set_interval(seconds: float) -> void:
	spawn_interval = max(0.05, seconds)
	if _timer:
		_timer.wait_time = spawn_interval
		if _timer.is_stopped() and start_on_ready:
			_timer.start()

func _collect_markers() -> void:
	_markers.clear()
	_occupied.clear()

	# 0) Séquence par noms: marker2D, marker2D2, ..., marker2Dn
	if use_sequential_marker_names:
		var root: Node = null
		# Si un conteneur est indiqué, il est prioritaire pour cette stratégie
		if marker_container_path != NodePath():
			root = get_node_or_null(marker_container_path)
		# Sinon, on utilise la racine séquentielle fournie (ou self par défaut)
		if root == null:
			root = get_node_or_null(sequential_markers_root) if (sequential_markers_root != NodePath()) else self
		if root:
			_gather_markers_by_sequence(root, _markers)

	# 1) Liste explicite
	for p in markers:
		var n := get_node_or_null(p)
		if n is Marker2D:
			_markers.append(n as Marker2D)

	# 2) Conteneur (recherche récursive) si rien trouvé jusque-là
	if marker_container_path != NodePath() and _markers.is_empty():
		var container := get_node_or_null(marker_container_path)
		if container:
			_gather_markers_recursive(container, _markers)

	# 3) Groupe
	if _markers.is_empty() and marker_group.strip_edges() != "":
		for n in get_tree().get_nodes_in_group(marker_group.strip_edges()):
			if n is Marker2D:
				_markers.append(n as Marker2D)

	# 4) Fallback: scan complet de la scène courante
	if _markers.is_empty() and search_whole_scene_fallback and get_tree().current_scene:
		_gather_markers_recursive(get_tree().current_scene, _markers)

	# Dédup + logs
	var seen := {}
	var unique: Array[Marker2D] = []
	for m in _markers:
		if not seen.has(m.get_instance_id()):
			seen[m.get_instance_id()] = true
			unique.append(m)
	_markers = unique

	if _markers.is_empty():
		print_verbose("CollectibleSpawner: aucun Marker2D trouvé après collecte.")
	#else:
		#print("CollectibleSpawner: ", _markers.size(), " Marker2D trouvés:")
		#for m in _markers:
			#print(" - ", m.get_path())

func _gather_markers_recursive(root: Node, out: Array[Marker2D]) -> void:
	for child in root.get_children():
		if child is Marker2D:
			out.append(child as Marker2D)
		_gather_markers_recursive(child, out)

# Recherche séquentielle: marker2D, marker2D2, marker2D3, ...
# Supporte aussi la variante 'Marker2D' si utilisé dans la scène.
func _gather_markers_by_sequence(root: Node, out: Array[Marker2D]) -> void:
	var i := 1
	while true:
		var name1 := "marker2D" if i == 1 else "marker2D%d" % i
		var node := root.get_node_or_null(NodePath(name1))
		if node == null:
			var name2 := "Marker2D" if i == 1 else "Marker2D%d" % i
			node = root.get_node_or_null(NodePath(name2))
		if node == null:
			# On arrête à la première lacune pour respecter une séquence continue
			break
		if node is Marker2D:
			out.append(node as Marker2D)
		else:
			push_warning("%s existe sous %s mais n'est pas un Marker2D" % [node.name, root.get_path()])
		i += 1
