extends Node

signal seals_changed(total: int)
signal health_changed(current: int, maximum: int)
signal message_changed(text: String)

const SAVE_PATH := "user://shrouded_keep_save.json"

var zone_index := 0
var seals := 0
var health := 6
var max_health := 6
var defeated_bosses: Array[String] = []
var discovered_lore: Array[String] = []
var checkpoint_position := Vector3.ZERO

func reset_run() -> void:
	zone_index = 0
	seals = 0
	health = max_health
	defeated_bosses.clear()
	discovered_lore.clear()
	checkpoint_position = Vector3.ZERO
	seals_changed.emit(seals)
	health_changed.emit(health, max_health)
	message_changed.emit("The Shrouded Keep waits beyond the blue ravine.")

func add_seal() -> void:
	seals += 1
	seals_changed.emit(seals)
	message_changed.emit("A moon seal burns cold in your hand.")

func damage_player(amount: int) -> void:
	health = max(0, health - amount)
	health_changed.emit(health, max_health)

func heal_full() -> void:
	health = max_health
	health_changed.emit(health, max_health)

func save_game() -> void:
	var data := {
		"zone_index": zone_index,
		"seals": seals,
		"health": health,
		"max_health": max_health,
		"defeated_bosses": defeated_bosses,
		"discovered_lore": discovered_lore,
		"checkpoint_position": [checkpoint_position.x, checkpoint_position.y, checkpoint_position.z],
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		message_changed.emit("Checkpoint saved.")

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	zone_index = int(parsed.get("zone_index", 0))
	seals = int(parsed.get("seals", 0))
	health = int(parsed.get("health", max_health))
	max_health = int(parsed.get("max_health", max_health))
	defeated_bosses = parsed.get("defeated_bosses", [])
	discovered_lore = parsed.get("discovered_lore", [])
	var raw_pos: Array = parsed.get("checkpoint_position", [0.0, 0.0, 0.0])
	checkpoint_position = Vector3(float(raw_pos[0]), float(raw_pos[1]), float(raw_pos[2]))
	seals_changed.emit(seals)
	health_changed.emit(health, max_health)
	message_changed.emit("Checkpoint loaded.")
	return true
