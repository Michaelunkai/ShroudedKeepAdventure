extends CharacterBody3D

signal attack_performed(origin: Vector3, radius: float, damage: int)
signal interacted(origin: Vector3)
signal stamina_changed(current: float, maximum: float)

@export var move_speed := 7.0
@export var lane_speed := 4.2
@export var dodge_speed := 15.0
@export var attack_radius := 2.25
@export var attack_damage := 2
@export var max_stamina := 100.0

var _attack_cooldown := 0.0
var _dodge_timer := 0.0
var _combo_timer := 0.0
var _combo_step := 0
var _facing := 1.0
var stamina := 100.0
var torso: MeshInstance3D
var sword: MeshInstance3D
var left_arm: MeshInstance3D
var right_arm: MeshInstance3D

func _ready() -> void:
	name = "Player"
	add_to_group("player")
	stamina = max_stamina
	_build_figure()

func _physics_process(delta: float) -> void:
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_dodge_timer = maxf(0.0, _dodge_timer - delta)
	_combo_timer = maxf(0.0, _combo_timer - delta)
	if _combo_timer <= 0.0:
		_combo_step = 0
	stamina = minf(max_stamina, stamina + 24.0 * delta)
	stamina_changed.emit(stamina, max_stamina)
	var move_x := Input.get_axis("move_left", "move_right")
	var move_z := Input.get_axis("lane_up", "lane_down")
	if absf(move_x) > 0.01:
		_facing = signf(move_x)
	var speed := dodge_speed if _dodge_timer > 0.0 else move_speed
	velocity = Vector3(move_x * speed, 0.0, move_z * lane_speed)
	move_and_slide()
	_animate_figure(delta, move_x, move_z)
	if Input.is_action_just_pressed("attack") and _attack_cooldown <= 0.0 and stamina >= 12.0:
		stamina -= 12.0
		_combo_step = (_combo_step + 1) % 3
		_combo_timer = 0.72
		_attack_cooldown = 0.42
		var combo_damage := attack_damage + _combo_step
		attack_performed.emit(global_position + Vector3(_facing * 1.25, 0.85, 0.0), attack_radius + float(_combo_step) * 0.25, combo_damage)
	if Input.is_action_just_pressed("dodge") and _dodge_timer <= 0.0 and stamina >= 25.0:
		stamina -= 25.0
		_dodge_timer = 0.18
	if Input.is_action_just_pressed("interact"):
		interacted.emit(global_position)

func hurt(amount: int) -> void:
	GameState.damage_player(amount)
	if GameState.health <= 0:
		global_position = GameState.checkpoint_position
		GameState.heal_full()
		GameState.message_changed.emit("The fog pulls you back to the last checkpoint.")

func _build_figure() -> void:
	torso = _box("cuirass", Vector3(0, 1.12, 0), Vector3(0.62, 0.92, 0.34), Color(0.08, 0.16, 0.34), Color(0.0, 0.12, 0.65))
	var head := _sphere("head", Vector3(0, 1.78, 0), 0.22, Color(0.55, 0.5, 0.74), Color(0.16, 0.14, 0.36))
	var helm := _box("helmet crest", Vector3(0, 2.01, 0), Vector3(0.38, 0.12, 0.24), Color(0.12, 0.18, 0.34), Color(0.05, 0.18, 0.55))
	var cloak := _box("blue cloak", Vector3(-0.12, 1.05, 0.24), Vector3(0.72, 1.18, 0.08), Color(0.02, 0.08, 0.28), Color(0.0, 0.15, 0.7))
	cloak.rotation_degrees.x = -8
	left_arm = _box("left arm", Vector3(-0.48, 1.18, 0), Vector3(0.16, 0.82, 0.16), Color(0.08, 0.14, 0.28), Color(0.0, 0.1, 0.45))
	right_arm = _box("right sword arm", Vector3(0.48, 1.18, 0), Vector3(0.16, 0.82, 0.16), Color(0.08, 0.14, 0.28), Color(0.0, 0.1, 0.45))
	_box("left leg", Vector3(-0.18, 0.42, 0), Vector3(0.18, 0.76, 0.18), Color(0.06, 0.1, 0.2), Color(0.0, 0.08, 0.34))
	_box("right leg", Vector3(0.18, 0.42, 0), Vector3(0.18, 0.76, 0.18), Color(0.06, 0.1, 0.2), Color(0.0, 0.08, 0.34))
	_box("left boot", Vector3(-0.2, 0.08, -0.04), Vector3(0.25, 0.16, 0.34), Color(0.02, 0.03, 0.07), Color(0.0, 0.04, 0.16))
	_box("right boot", Vector3(0.2, 0.08, -0.04), Vector3(0.25, 0.16, 0.34), Color(0.02, 0.03, 0.07), Color(0.0, 0.04, 0.16))
	sword = _box("moon blade", Vector3(0.72, 1.12, -0.04), Vector3(0.08, 1.45, 0.08), Color(0.82, 0.9, 1.0), Color(0.18, 0.48, 1.0))
	sword.rotation_degrees.z = -26
	head.name = "visible human head"
	helm.name = "moonlit helmet crest"
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.34
	capsule.height = 1.55
	shape.shape = capsule
	shape.position = Vector3(0, 0.95, 0)
	add_child(shape)

func _animate_figure(_delta: float, move_x: float, move_z: float) -> void:
	var moving := absf(move_x) + absf(move_z) > 0.05
	var sway := sin(Time.get_ticks_msec() * 0.012) * (8.0 if moving else 2.5)
	if is_instance_valid(torso):
		torso.rotation_degrees.z = sway * 0.08
	if is_instance_valid(left_arm):
		left_arm.rotation_degrees.x = sway
	if is_instance_valid(right_arm):
		right_arm.rotation_degrees.x = -sway
	if is_instance_valid(sword):
		sword.rotation_degrees.z = -26 + (-44 if _attack_cooldown > 0.28 else 0)

func _box(label: String, pos: Vector3, size: Vector3, albedo: Color, emission: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = mesh
	instance.position = pos
	instance.material_override = _mat(albedo, emission)
	add_child(instance)
	return instance

func _sphere(label: String, pos: Vector3, radius: float, albedo: Color, emission: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = mesh
	instance.position = pos
	instance.material_override = _mat(albedo, emission)
	add_child(instance)
	return instance

func _mat(albedo: Color, emission: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.emission_enabled = true
	material.emission = emission
	material.emission_energy_multiplier = 0.35
	return material
