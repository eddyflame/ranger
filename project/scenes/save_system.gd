extends Node
class_name SaveSystem

const SAVE_PATH = "user://rangers_path_save.json"

static func save_game(player: Node2D) -> void:
	if not player: return
	
	var save_data = {
		"level": player.level,
		"xp": player.get_xp(),
		"gold": player.get_gold(),
		"skill_points": player.get_skill_points(),
		"strength": player.get_strength(),
		"agility": player.get_agility(),
		"intelligence": player.get_intelligence(),
		"skill_q_level": player.get_skill_q_level(),
		"skill_w_level": player.get_skill_w_level(),
		"skill_e_level": player.get_skill_e_level(),
		"inventory": player.get_inventory()
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_data)
		file.store_string(json_string)
		file.close()
		print("Game saved successfully to: ", SAVE_PATH)

static func load_game(player: Node2D) -> bool:
	if not player: return false
	if not FileAccess.file_exists(SAVE_PATH):
		return false
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
		
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_err = json.parse(json_string)
	if parse_err != OK:
		return false
		
	var save_data = json.data
	if typeof(save_data) != TYPE_DICTIONARY:
		return false
		
	# Restore all stats to player character
	player.set_level(int(save_data.get("level", 1)))
	player.set_xp(int(save_data.get("xp", 0)))
	player.set_gold(int(save_data.get("gold", 0)))
	player.set_skill_points(int(save_data.get("skill_points", 0)))
	player.set_strength(int(save_data.get("strength", 10)))
	player.set_agility(int(save_data.get("agility", 10)))
	player.set_intelligence(int(save_data.get("intelligence", 10)))
	player.set_skill_q_level(int(save_data.get("skill_q_level", 0)))
	player.set_skill_w_level(int(save_data.get("skill_w_level", 0)))
	player.set_skill_e_level(int(save_data.get("skill_e_level", 0)))
	player.set_inventory(save_data.get("inventory", []))
	
	# Full restore of HP and MP to the new limits after STR/INT calculation
	player.set_hp(player.get_total_max_hp())
	player.set_mp(player.get_total_max_mp())
	
	print("Game loaded successfully from: ", SAVE_PATH)
	return true

static func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("Save file deleted.")
