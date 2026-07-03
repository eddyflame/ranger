extends Node
class_name SaveSystem

const SAVE_PATH = "user://rangers_path_save.json"

static func save_game(player: Node2D, next_level_override: int = -1) -> void:
	if not player: return
	
	# Determine current stage index from current scene filename if not overridden
	var level_index = 1
	if next_level_override > 0:
		level_index = next_level_override
	else:
		var current_scene = player.get_tree().current_scene
		if current_scene:
			var path = current_scene.scene_file_path
			if path.contains("stage2"):
				level_index = 2
			elif path.contains("stage3"):
				level_index = 3
			else:
				level_index = 1
	
	# Read the previous max_unlocked_level from existing save file if it exists
	var max_unlocked_level = 1
	if FileAccess.file_exists(SAVE_PATH):
		var file_read = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file_read:
			var old_text = file_read.get_as_text()
			file_read.close()
			var json_old = JSON.new()
			if json_old.parse(old_text) == OK:
				var old_data = json_old.get_data()
				if typeof(old_data) == TYPE_DICTIONARY:
					max_unlocked_level = int(old_data.get("max_unlocked_level", 1))
					
	# The max unlocked level is the highest stage the player has unlocked/reached
	max_unlocked_level = max(max_unlocked_level, level_index)
	
	var save_data = {
		"level_index": level_index,
		"max_unlocked_level": max_unlocked_level,
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
