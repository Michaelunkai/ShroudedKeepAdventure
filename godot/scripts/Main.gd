extends Node3D

const PlayerController := preload("res://scripts/PlayerController.gd")
const EnemyController := preload("res://scripts/EnemyController.gd")

var player: CharacterBody3D
var camera: Camera3D
var hud_title: Label
var hud_stats: Label
var hud_message: Label
var hud_controls: Label
var boss_label: Label
var zone_root: Node3D
var gate_area: Area3D
var seal_area: Area3D
var checkpoint_area: Area3D
var lore_areas: Array[Area3D] = []
var enemies: Array[Node] = []
var boss_enemy: Node = null

var zones := [
	{"name": "Blue Ravine", "goal": "Claim the ravine seal and cross the bridge.", "length": 62.0, "seal": 28.0, "gate": 55.0, "enemy_count": 3, "boss": false},
	{"name": "Outer Wall", "goal": "Break the shadow patrol and unlock the tower road.", "length": 74.0, "seal": 38.0, "gate": 68.0, "enemy_count": 4, "boss": true},
	{"name": "Flooded Arch", "goal": "Follow the blue water under the ruined keep.", "length": 82.0, "seal": 45.0, "gate": 76.0, "enemy_count": 5, "boss": false},
	{"name": "Starfall Courtyard", "goal": "Survive the watchers under the violet sky.", "length": 88.0, "seal": 48.0, "gate": 82.0, "enemy_count": 5, "boss": true},
	{"name": "Bone Library", "goal": "Find the final lore fragment in the dead archive.", "length": 92.0, "seal": 52.0, "gate": 86.0, "enemy_count": 6, "boss": false},
	{"name": "Moon Tower", "goal": "Defeat the Moon-Crowned Keeper.", "length": 96.0, "seal": -1.0, "gate": 90.0, "enemy_count": 4, "boss": true},
]

func _ready() -> void:
	_build_world()
	_build_hud()
	GameState.message_changed.connect(_set_message)
	GameState.health_changed.connect(_update_hud)
	GameState.seals_changed.connect(_on_seals_changed)
	GameState.lore_changed.connect(_on_lore_changed)
	GameState.reset_run()
	_load_zone(0)

func _process(_delta: float) -> void:
	if is_instance_valid(player) and is_instance_valid(camera):
		camera.global_position.x = lerpf(camera.global_position.x, player.global_position.x + 3.5, 0.08)
		camera.global_position.z = lerpf(camera.global_position.z, 11.0, 0.08)
		camera.look_at(player.global_position + Vector3(3.0, 1.2, 0.0), Vector3.UP)
	if Input.is_action_just_pressed("pause"):
		get_tree().paused = not get_tree().paused
		_set_message("Paused. Press Esc again to continue." if get_tree().paused else "The keep breathes again.")

func _build_world() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.02, 0.24)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.16, 0.18, 0.42)
	env.ambient_light_energy = 0.7
	env.glow_enabled = true
	env.glow_intensity = 0.55
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.035
	env.volumetric_fog_albedo = Color(0.09, 0.2, 0.75)
	environment.environment = env
	add_child(environment)
	var moon := DirectionalLight3D.new()
	moon.name = "Magenta Moon Light"
	moon.light_color = Color(0.78, 0.34, 1.0)
	moon.light_energy = 2.8
	moon.rotation_degrees = Vector3(-42, -34, 0)
	add_child(moon)
	camera = Camera3D.new()
	camera.name = "CinematicCamera"
	camera.current = true
	camera.fov = 52
	camera.position = Vector3(8, 5.4, 12)
	add_child(camera)
	zone_root = Node3D.new()
	zone_root.name = "ZoneRoot"
	add_child(zone_root)
	player = CharacterBody3D.new()
	player.set_script(PlayerController)
	player.attack_performed.connect(_on_player_attack)
	player.interacted.connect(_on_player_interact)
	add_child(player)

func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "HUD"
	add_child(canvas)
	hud_title = Label.new()
	hud_title.position = Vector2(28, 18)
	hud_title.add_theme_font_size_override("font_size", 28)
	canvas.add_child(hud_title)
	hud_stats = Label.new()
	hud_stats.position = Vector2(980, 22)
	hud_stats.add_theme_font_size_override("font_size", 20)
	canvas.add_child(hud_stats)
	boss_label = Label.new()
	boss_label.position = Vector2(420, 92)
	boss_label.size = Vector2(520, 36)
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_label.add_theme_font_size_override("font_size", 20)
	canvas.add_child(boss_label)
	hud_message = Label.new()
	hud_message.position = Vector2(44, 642)
	hud_message.size = Vector2(1180, 52)
	hud_message.add_theme_font_size_override("font_size", 22)
	hud_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	canvas.add_child(hud_message)
	hud_controls = Label.new()
	hud_controls.position = Vector2(34, 94)
	hud_controls.add_theme_font_size_override("font_size", 16)
	hud_controls.text = "A/D move  W/S lane  J attack  K dodge  E interact  Esc pause"
	canvas.add_child(hud_controls)

func _load_zone(index: int) -> void:
	GameState.zone_index = clampi(index, 0, zones.size() - 1)
	for child in zone_root.get_children():
		child.queue_free()
	enemies.clear()
	lore_areas.clear()
	boss_enemy = null
	var zone = zones[GameState.zone_index]
	hud_title.text = "%s - %s" % [zone.name, zone.goal]
	player.global_position = Vector3(2, 0, 0)
	GameState.checkpoint_position = player.global_position
	_build_zone_geometry(zone)
	_spawn_interactables(zone)
	_spawn_enemies(zone)
	GameState.save_game()
	_update_hud(GameState.health, GameState.max_health)
	_set_message("Entered %s. %s" % [zone.name, zone.goal])

func _build_zone_geometry(zone: Dictionary) -> void:
	_create_box("blue fog path", Vector3(zone.length * 0.5, -0.08, 0), Vector3(zone.length, 0.16, 7.0), Color(0.01, 0.04, 0.14), Color(0.02, 0.24, 0.8))
	for x in range(0, int(zone.length), 8):
		_create_box("left cliff", Vector3(x + 2, 2.2, -4.6), Vector3(3.5, 4.4 + sin(float(x)) * 1.4, 0.9), Color(0.02, 0.025, 0.06), Color(0.02, 0.08, 0.24))
		_create_box("right wall", Vector3(x + 3, 1.65, 4.45), Vector3(4.0, 3.3, 0.8), Color(0.03, 0.035, 0.08), Color(0.03, 0.08, 0.22))
	for tower_x in [14.0, zone.length * 0.48, zone.length - 10.0]:
		_create_box("tower", Vector3(tower_x, 4.5, 4.85), Vector3(2.4, 9.0, 2.4), Color(0.015, 0.018, 0.04), Color(0.11, 0.07, 0.22))
		_create_box("tower crown", Vector3(tower_x, 9.5, 4.85), Vector3(3.4, 1.0, 3.4), Color(0.015, 0.018, 0.04), Color(0.28, 0.06, 0.48))
	var moon := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 2.2
	moon.mesh = sphere
	moon.position = Vector3(zone.length * 0.72, 17.0, -15.0)
	moon.material_override = _material(Color(1.0, 0.28, 0.95), Color(1.0, 0.12, 0.9), 2.3)
	zone_root.add_child(moon)

func _spawn_interactables(zone: Dictionary) -> void:
	if float(zone.seal) >= 0.0:
		seal_area = _create_trigger("MoonSeal", Vector3(float(zone.seal), 0.8, -1.8), Vector3(1.2, 1.6, 1.2), Color(0.95, 0.18, 1.0), Color(1.0, 0.1, 0.9), 2.5)
	gate_area = _create_trigger("MoonGate", Vector3(float(zone.gate), 1.5, 0.0), Vector3(1.5, 3.0, 5.0), Color(0.2, 0.08, 0.34), Color(0.8, 0.12, 1.0), 1.2)
	checkpoint_area = _create_trigger("Checkpoint", Vector3(7.0, 0.55, 2.3), Vector3(1.1, 1.1, 1.1), Color(0.1, 0.42, 1.0), Color(0.0, 0.44, 1.0), 1.4)
	var lore := _create_trigger("LoreStone", Vector3(float(zone.length) * 0.62, 0.7, 2.55), Vector3(1.0, 1.4, 0.55), Color(0.05, 0.04, 0.11), Color(0.28, 0.14, 0.8), 0.9)
	lore.set_meta("lore_id", "%s_lore" % zone.name.to_snake_case())
	lore.set_meta("lore_text", "Lore found: %s remembers a knight who entered before you." % zone.name)
	lore_areas.append(lore)

func _spawn_enemies(zone: Dictionary) -> void:
	var count := int(zone.enemy_count)
	for i in range(count):
		var enemy := CharacterBody3D.new()
		enemy.set_script(EnemyController)
		enemy.setup("Shadow Figure", 3 + GameState.zone_index, 1, false)
		enemy.target = player
		enemy.position = Vector3(14 + i * 8, 0, -1.6 + (i % 3) * 1.6)
		enemy.defeated.connect(_on_enemy_defeated)
		zone_root.add_child(enemy)
		enemies.append(enemy)
	if bool(zone.boss):
		var boss := CharacterBody3D.new()
		boss.set_script(EnemyController)
		boss.setup("Moon-Crowned Threat", 10 + GameState.zone_index * 2, 2, true)
		boss.target = player
		boss.position = Vector3(float(zone.length) - 14.0, 0, 0)
		boss.defeated.connect(_on_enemy_defeated)
		zone_root.add_child(boss)
		enemies.append(boss)
		boss_enemy = boss

func _on_player_attack(origin: Vector3, radius: float, damage: int) -> void:
	_create_flash(origin)
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy) and enemy.global_position.distance_to(origin) <= radius and enemy.has_method("hurt"):
			enemy.hurt(damage)

func _on_player_interact(origin: Vector3) -> void:
	if is_instance_valid(seal_area) and origin.distance_to(seal_area.global_position) < 2.0:
		GameState.add_seal()
		seal_area.queue_free()
	if is_instance_valid(checkpoint_area) and origin.distance_to(checkpoint_area.global_position) < 2.1:
		GameState.checkpoint_position = player.global_position
		GameState.save_game()
	for lore in lore_areas:
		if is_instance_valid(lore) and origin.distance_to(lore.global_position) < 2.0:
			GameState.add_lore(str(lore.get_meta("lore_id")), str(lore.get_meta("lore_text")))
	if is_instance_valid(gate_area) and origin.distance_to(gate_area.global_position) < 3.0:
		if GameState.zone_index < zones.size() - 1:
			_load_zone(GameState.zone_index + 1)
		else:
			_set_message("The Moon-Crowned Keeper falls. The Shrouded Keep is unbound.")

func _on_enemy_defeated(enemy: Node) -> void:
	enemies.erase(enemy)
	if enemy == boss_enemy:
		boss_enemy = null
	_set_message("A threat dissolves into violet ash.")

func _update_hud(_current := 0, _maximum := 0) -> void:
	hud_stats.text = "Health %d/%d   Seals %d   Lore %d/6" % [GameState.health, GameState.max_health, GameState.seals, GameState.discovered_lore.size()]
	if is_instance_valid(boss_enemy):
		boss_label.text = "%s   HP %d/%d" % [boss_enemy.display_name, boss_enemy.health, boss_enemy.max_health]
	else:
		boss_label.text = ""

func _on_seals_changed(_total: int) -> void:
	_update_hud(GameState.health, GameState.max_health)

func _on_lore_changed(_total: int) -> void:
	_update_hud(GameState.health, GameState.max_health)

func _set_message(text: String) -> void:
	hud_message.text = text

func _create_box(label: String, pos: Vector3, size: Vector3, albedo: Color, emission: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = mesh
	instance.position = pos
	instance.material_override = _material(albedo, emission, 0.18)
	zone_root.add_child(instance)
	return instance

func _create_trigger(label: String, pos: Vector3, size: Vector3, albedo: Color, emission: Color, energy: float) -> Area3D:
	var area := Area3D.new()
	area.name = label
	area.position = pos
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = _material(albedo, emission, energy)
	area.add_child(mesh)
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	area.add_child(shape)
	zone_root.add_child(area)
	return area

func _create_flash(pos: Vector3) -> void:
	var flash := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.55
	flash.mesh = sphere
	flash.position = pos
	flash.material_override = _material(Color(0.8, 0.92, 1.0), Color(0.4, 0.75, 1.0), 3.0)
	add_child(flash)
	var tween := create_tween()
	tween.tween_property(flash, "scale", Vector3(2.5, 2.5, 2.5), 0.16)
	tween.tween_callback(flash.queue_free)

func _material(albedo: Color, emission: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.emission_enabled = true
	material.emission = emission
	material.emission_energy_multiplier = energy
	material.roughness = 0.72
	return material
