extends CharacterBody3D

signal attack_performed(origin: Vector3, radius: float, damage: int)
signal interacted(origin: Vector3)

@export var move_speed := 7.0
@export var lane_speed := 4.2
@export var dodge_speed := 15.0
@export var attack_radius := 2.25
@export var attack_damage := 2

var _attack_cooldown := 0.0
var _dodge_timer := 0.0
var _facing := 1.0

func _ready() -> void:
	name = "Player"
	add_to_group("player")
	_build_figure()

func _physics_process(delta: float) -> void:
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	_dodge_timer = maxf(0.0, _dodge_timer - delta)
	var move_x := Input.get_axis("move_left", "move_right")
	var move_z := Input.get_axis("lane_up", "lane_down")
	if absf(move_x) > 0.01:
		_facing = signf(move_x)
	var speed := dodge_speed if _dodge_timer > 0.0 else move_speed
	velocity = Vector3(move_x * speed, 0.0, move_z * lane_speed)
	move_and_slide()
	if Input.is_action_just_pressed("attack") and _attack_cooldown <= 0.0:
		_attack_cooldown = 0.42
		attack_performed.emit(global_position + Vector3(_facing * 1.1, 0.4, 0.0), attack_radius, attack_damage)
	if Input.is_action_just_pressed("dodge") and _dodge_timer <= 0.0:
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
	var body_mesh := CapsuleMesh.new()
	body_mesh.radius = 0.34
	body_mesh.height = 1.55
	var body := MeshInstance3D.new()
	body.mesh = body_mesh
	body.position = Vector3(0, 0.95, 0)
	body.material_override = _mat(Color(0.1, 0.34, 1.0), Color(0.0, 0.12, 0.9))
	add_child(body)
	var sword_mesh := BoxMesh.new()
	sword_mesh.size = Vector3(0.08, 1.25, 0.08)
	var sword := MeshInstance3D.new()
	sword.mesh = sword_mesh
	sword.position = Vector3(0.58, 0.96, 0)
	sword.rotation_degrees.z = -25
	sword.material_override = _mat(Color(0.82, 0.9, 1.0), Color(0.18, 0.48, 1.0))
	add_child(sword)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.34
	capsule.height = 1.55
	shape.shape = capsule
	shape.position = Vector3(0, 0.95, 0)
	add_child(shape)

func _mat(albedo: Color, emission: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.emission_enabled = true
	material.emission = emission
	material.emission_energy_multiplier = 0.35
	return material
