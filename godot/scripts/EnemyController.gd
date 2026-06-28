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
	if not is_instance_valid(target):
		return
	var offset := target.global_position - global_position
	var distance := offset.length()
	if distance < aggro_range and distance > attack_range:
		velocity = offset.normalized() * move_speed
		velocity.y = 0
		move_and_slide()
	elif distance <= attack_range and _attack_cooldown <= 0.0:
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
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.38 if not boss else 0.7
	mesh.height = 1.65 if not boss else 2.5
	var figure := MeshInstance3D.new()
	figure.mesh = mesh
	figure.position = Vector3(0, mesh.height * 0.5, 0)
	figure.material_override = _mat()
	add_child(figure)
	var eye_mesh := SphereMesh.new()
	eye_mesh.radius = 0.08 if not boss else 0.14
	var eye := MeshInstance3D.new()
	eye.mesh = eye_mesh
	eye.position = Vector3(0.0, mesh.height * 0.78, -0.32)
	eye.material_override = _eye_mat()
	add_child(eye)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = mesh.radius
	capsule.height = mesh.height
	shape.shape = capsule
	shape.position = Vector3(0, mesh.height * 0.5, 0)
	add_child(shape)

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
