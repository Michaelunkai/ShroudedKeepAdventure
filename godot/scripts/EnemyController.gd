extends CharacterBody3D

signal defeated(enemy: Node)

@export var display_name := "Shadow"
@export var max_health := 3
@export var move_speed := 2.6
@export var attack_damage := 1
@export var attack_range := 1.45
@export var aggro_range := 8.0
@export var boss := false

var health := 3
var target: Node3D
var _attack_cooldown := 0.0
var _telegraph_timer := 0.0
var chest: MeshInstance3D
var weapon: MeshInstance3D

func _ready() -> void:
	health = max_health
	add_to_group("enemy")
	_build_figure()

func setup(new_name: String, hp: int, damage: int, is_boss: bool) -> void:
	display_name = new_name
	max_health = hp
	health = hp
	attack_damage = damage
	boss = is_boss

func _physics_process(delta: float) -> void:
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_telegraph_timer = maxf(0.0, _telegraph_timer - delta)
	_animate_threat()
	if not is_instance_valid(target):
		return
	var offset := target.global_position - global_position
	var distance := offset.length()
	if distance < aggro_range and distance > attack_range:
		velocity = offset.normalized() * move_speed
		velocity.y = 0
		move_and_slide()
	elif distance <= attack_range and _attack_cooldown <= 0.0:
		_telegraph_timer = 0.24
		_attack_cooldown = 1.15 if not boss else 0.78
		if target.has_method("hurt"):
			target.hurt(attack_damage)

func hurt(amount: int) -> void:
	health -= amount
	GameState.message_changed.emit("%s staggers." % display_name)
	if health <= 0:
		defeated.emit(self)
		queue_free()

func _build_figure() -> void:
	var scale_factor := 1.0 if not boss else 1.55
	chest = _box("humanoid shadow chest", Vector3(0, 1.05 * scale_factor, 0), Vector3(0.58, 0.9, 0.28) * scale_factor, _mat())
	_sphere("gaunt face", Vector3(0, 1.74 * scale_factor, 0), 0.2 * scale_factor, _mat())
	_box("left shadow arm", Vector3(-0.42 * scale_factor, 1.1 * scale_factor, 0), Vector3(0.14, 0.78, 0.14) * scale_factor, _mat())
	_box("right shadow arm", Vector3(0.42 * scale_factor, 1.1 * scale_factor, 0), Vector3(0.14, 0.78, 0.14) * scale_factor, _mat())
	_box("left shadow leg", Vector3(-0.17 * scale_factor, 0.4 * scale_factor, 0), Vector3(0.16, 0.72, 0.16) * scale_factor, _mat())
	_box("right shadow leg", Vector3(0.17 * scale_factor, 0.4 * scale_factor, 0), Vector3(0.16, 0.72, 0.16) * scale_factor, _mat())
	weapon = _box("cruel violet blade", Vector3(0.62 * scale_factor, 1.0 * scale_factor, -0.02), Vector3(0.07, 1.1, 0.07) * scale_factor, _eye_mat())
	weapon.rotation_degrees.z = 32
	var eye := _sphere("magenta eye", Vector3(0.0, 1.8 * scale_factor, -0.21 * scale_factor), 0.06 * scale_factor, _eye_mat())
	eye.name = "burning humanoid eye"
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4 * scale_factor
	capsule.height = 1.75 * scale_factor
	shape.shape = capsule
	shape.position = Vector3(0, 0.9 * scale_factor, 0)
	add_child(shape)

func _animate_threat() -> void:
	var pulse := 0.2 + sin(Time.get_ticks_msec() * 0.006) * 0.08
	if is_instance_valid(chest):
		chest.scale = Vector3.ONE * (1.0 + pulse * 0.05)
	if is_instance_valid(weapon):
		weapon.rotation_degrees.z = 32 + (40 if _telegraph_timer > 0.0 else 0)

func _box(label: String, pos: Vector3, size: Vector3, material: StandardMaterial3D) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = mesh
	instance.position = pos
	instance.material_override = material
	add_child(instance)
	return instance

func _sphere(label: String, pos: Vector3, radius: float, material: StandardMaterial3D) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = mesh
	instance.position = pos
	instance.material_override = material
	add_child(instance)
	return instance

func _mat() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.08, 0.02, 0.13)
	material.emission_enabled = true
	material.emission = Color(0.55, 0.05, 0.95)
	material.emission_energy_multiplier = 0.35 if not boss else 0.9
	return material

func _eye_mat() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.24, 0.95)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.2, 1.0)
	material.emission_energy_multiplier = 1.8
	return material
