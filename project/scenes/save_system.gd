extends Node
class_name SaveSystem

const SAVE_PATH = "user://rangers_path_save.json"

static var is_continuing: bool = false
static var unlocked_shop_items: Array = []

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
			elif path.contains("stage4"):
				level_index = 4
			elif path.contains("stage5"):
				level_index = 5
			elif path.contains("stage6"):
				level_index = 6
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
		"skill_r_level": player.get_skill_r_level(),
		"talent_crit_level": player.get_talent_crit_level(),
		"talent_evasion_level": player.get_talent_evasion_level(),
		"talent_lifesteal_level": player.get_talent_lifesteal_level(),
		"talent_speed_level": player.get_talent_speed_level(),
		"inventory": player.get_inventory(),
		"unlocked_shop_items": unlocked_shop_items
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
		
	# Restore unlocked shop catalog and gold/inventory (always carried over/accumulated)
	unlocked_shop_items = save_data.get("unlocked_shop_items", [])
	player.set_gold(int(save_data.get("gold", 0)))
	player.set_inventory(save_data.get("inventory", []))
	
	if is_continuing:
		# Restore exact mid-stage character progression if continuing
		player.set_level(int(save_data.get("level", 1)))
		player.set_xp(int(save_data.get("xp", 0)))
		player.set_skill_points(int(save_data.get("skill_points", 0)))
		player.set_strength(int(save_data.get("strength", 10)))
		player.set_agility(int(save_data.get("agility", 10)))
		player.set_intelligence(int(save_data.get("intelligence", 10)))
		player.set_skill_q_level(int(save_data.get("skill_q_level", 0)))
		player.set_skill_w_level(int(save_data.get("skill_w_level", 0)))
		player.set_skill_e_level(int(save_data.get("skill_e_level", 0)))
		player.set_skill_r_level(int(save_data.get("skill_r_level", 0)))
		player.set_talent_crit_level(int(save_data.get("talent_crit_level", 0)))
		player.set_talent_evasion_level(int(save_data.get("talent_evasion_level", 0)))
		player.set_talent_lifesteal_level(int(save_data.get("talent_lifesteal_level", 0)))
		player.set_talent_speed_level(int(save_data.get("talent_speed_level", 0)))
	else:
		# Reset progression to level 1 with 1 skill point for starting/restarting a stage
		player.set_level(1)
		player.set_xp(0)
		player.set_skill_points(1)
		player.set_strength(10)
		player.set_agility(10)
		player.set_intelligence(10)
		player.set_skill_q_level(0)
		player.set_skill_w_level(0)
		player.set_skill_e_level(0)
		player.set_skill_r_level(0)
		player.set_talent_crit_level(0)
		player.set_talent_evasion_level(0)
		player.set_talent_lifesteal_level(0)
		player.set_talent_speed_level(0)
		
	# Reset the continue flag after loading is done
	is_continuing = false
	
	# Full restore of HP and MP to the new limits after STR/INT calculation
	player.set_hp(player.get_total_max_hp())
	player.set_mp(player.get_total_max_mp())
	
	print("Game loaded successfully from: ", SAVE_PATH)
	return true

static func delete_save() -> void:
	unlocked_shop_items = []
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
		print("Save file deleted.")

static func register_unlocked_item(item_data: Dictionary) -> void:
	var item_name = item_data.get("name", "")
	if item_name == "": return
	
	# Skip common grade equipment
	if item_data.get("grade", "common") == "common":
		return
	
	if item_data.get("type", "") == "potion":
		return

	for existing in unlocked_shop_items:
		if existing.get("name", "") == item_name:
			return
			
	unlocked_shop_items.append(item_data)
	print("[Shop Catalog] Unlocked new item for purchase: ", item_name)

static func generate_graded_loot(is_boss: bool) -> Dictionary:
	var weapons = [
		{"name": "铁木长弓 (Elven Bow)", "type": "weapon", "atk_bonus": 6.0, "description": "+%d 点攻击力。"},
		{"name": "淬毒钢爪 (Poisoned Claws)", "type": "weapon", "atk_bonus": 8.0, "description": "+%d 点攻击力。"},
		{"name": "狂暴之刃 (Furious Blade)", "type": "weapon", "atk_bonus": 10.0, "description": "+%d 点攻击力。"},
		{"name": "勇者之剑 (Champion Sword)", "type": "weapon", "atk_bonus": 12.0, "set_name": "champion", "set_item_id": "champion_sword", "description": "+%d 物理攻击。"},
		{"name": "影刃匕首 (Shadow Dagger)", "type": "weapon", "atk_bonus": 9.0, "set_name": "shadow", "set_item_id": "shadow_dagger", "description": "+%d 物理攻击。"},
		{"name": "熔岩大剑 (Lava Greatsword)", "type": "weapon", "atk_bonus": 14.0, "set_name": "lava", "set_item_id": "lava_greatsword", "description": "+%d 物理攻击。"}
	]
	var armors = [
		{"name": "锁子硬甲 (Chainmail)", "type": "armor", "def_bonus": 2.0, "hp_bonus": 50.0, "description": "+%d 护甲, +%d 生命值。"},
		{"name": "皮质圆盾 (Leather Shield)", "type": "armor", "def_bonus": 3.0, "description": "+%d 点护甲保护。"},
		{"name": "精钢护板 (Steel Plate)", "type": "armor", "def_bonus": 4.0, "hp_bonus": 100.0, "description": "+%d 护甲, +%d 生命值。"},
		{"name": "勇者胸甲 (Champion Chestplate)", "type": "armor", "def_bonus": 3.0, "hp_bonus": 60.0, "set_name": "champion", "set_item_id": "champion_breastplate", "description": "+%d 物理防护, +%d 生命上限。"},
		{"name": "影之皮甲 (Shadow Leather)", "type": "armor", "def_bonus": 2.0, "hp_bonus": 45.0, "set_name": "shadow", "set_item_id": "shadow_leather", "description": "+%d 物理防护, +%d 生命上限。"},
		{"name": "熔岩重铠 (Lava Iron Armor)", "type": "armor", "def_bonus": 4.5, "hp_bonus": 110.0, "set_name": "lava", "set_item_id": "lava_iron_armor", "description": "+%d 物理防护, +%d 生命上限。"}
	]
	var boots = [
		{"name": "野外软鞋 (Wild Boots)", "type": "boots", "speed_bonus": 30.0, "description": "+%d 点移动速度。"},
		{"name": "飞燕战靴 (Swift Boots)", "type": "boots", "speed_bonus": 50.0, "description": "+%d 点移动速度。"},
		{"name": "影舞战靴 (Shadow Boots)", "type": "boots", "speed_bonus": 55.0, "set_name": "shadow", "set_item_id": "shadow_boots", "description": "+%d 点移动速度。"}
	]
	var crests = [
		{"name": "猎手徽章 (Hunter's Sigil)", "type": "crest", "atk_bonus": 8.0, "hp_bonus": 80.0, "speed_bonus": 25.0, "description": "+%d 攻击, +%d 生命, +%d 速度。"},
		{"name": "勇者徽章 (Champion Sigil)", "type": "crest", "atk_bonus": 6.0, "hp_bonus": 40.0, "set_name": "champion", "set_item_id": "champion_sigil", "description": "+%d 攻击力, +%d 生命值。"},
		{"name": "火山徽章 (Volcanic Sigil)", "type": "crest", "atk_bonus": 7.0, "hp_bonus": 70.0, "set_name": "lava", "set_item_id": "lava_sigil", "description": "+%d 攻击力, +%d 生命值。"}
	]

	var roll_cat = randf()
	var selected_template = {}
	if roll_cat <= 0.4:
		selected_template = weapons[randi() % weapons.size()].duplicate()
	elif roll_cat <= 0.7:
		selected_template = armors[randi() % armors.size()].duplicate()
	elif roll_cat <= 0.9:
		selected_template = boots[randi() % boots.size()].duplicate()
	else:
		selected_template = crests[randi() % crests.size()].duplicate()

	var roll_grade = randf()
	var grade = "common"
	var prefix = ""
	var stat_mult = 1.0
	var cost_mult = 1.0
	
	if is_boss:
		if roll_grade <= 0.10:
			grade = "legendary"
			prefix = "🟠[传说] "
			stat_mult = 3.5
			cost_mult = 5.0
		elif roll_grade <= 0.35:
			grade = "epic"
			prefix = "🟣[史诗] "
			stat_mult = 2.2
			cost_mult = 3.0
		elif roll_grade <= 0.70:
			grade = "rare"
			prefix = "🔵[精良] "
			stat_mult = 1.6
			cost_mult = 2.0
		elif roll_grade <= 0.90:
			grade = "uncommon"
			prefix = "🟢[优秀] "
			stat_mult = 1.3
			cost_mult = 1.5
		else:
			grade = "common"
			prefix = "⚪[普通] "
			stat_mult = 0.5
			cost_mult = 0.4
	else:
		if roll_grade <= 0.01:
			grade = "legendary"
			prefix = "🟠[传说] "
			stat_mult = 3.5
			cost_mult = 5.0
		elif roll_grade <= 0.05:
			grade = "epic"
			prefix = "🟣[史诗] "
			stat_mult = 2.2
			cost_mult = 3.0
		elif roll_grade <= 0.15:
			grade = "rare"
			prefix = "🔵[精良] "
			stat_mult = 1.6
			cost_mult = 2.0
		elif roll_grade <= 0.40:
			grade = "uncommon"
			prefix = "🟢[优秀] "
			stat_mult = 1.3
			cost_mult = 1.5
		else:
			grade = "common"
			prefix = "⚪[普通] "
			stat_mult = 0.5
			cost_mult = 0.4

	var item_data = {
		"type": selected_template.type,
		"grade": grade
	}

	if selected_template.has("set_name"):
		item_data["set_name"] = selected_template.set_name
		item_data["set_item_id"] = selected_template.set_item_id

	var base_atk = selected_template.get("atk_bonus", 0.0)
	var base_def = selected_template.get("def_bonus", 0.0)
	var base_hp = selected_template.get("hp_bonus", 0.0)
	var base_speed = selected_template.get("speed_bonus", 0.0)

	var final_atk = round(base_atk * stat_mult)
	var final_def = round(base_def * stat_mult)
	var final_hp = round(base_hp * stat_mult)
	var final_speed = round(base_speed * stat_mult)

	if base_atk > 0.0: item_data["atk_bonus"] = final_atk
	if base_def > 0.0: item_data["def_bonus"] = final_def
	if base_hp > 0.0: item_data["hp_bonus"] = final_hp
	if base_speed > 0.0: item_data["speed_bonus"] = final_speed
	
	if selected_template.has("lifesteal_percent"):
		item_data["lifesteal_percent"] = selected_template["lifesteal_percent"]

	# Shuffling and adding random bonus stats if grade is green or above!
	var bonus_pool = []
	if selected_template.type == "weapon":
		bonus_pool = [
			{"key": "crit_chance", "name": "暴击率", "values": {"uncommon": 0.05, "rare": 0.10, "epic": 0.15, "legendary": 0.25}, "format": "🟢+%d%% 暴击率"},
			{"key": "lifesteal_percent", "name": "生命吸取", "values": {"uncommon": 0.05, "rare": 0.10, "epic": 0.15, "legendary": 0.25}, "format": "🟢+%d%% 生命吸取"},
			{"key": "atk_bonus", "name": "额外攻击力", "values": {"uncommon": 3.0, "rare": 6.0, "epic": 10.0, "legendary": 18.0}, "format": "🟢+%d 物理攻击"},
			{"key": "speed_bonus", "name": "额外移动速度", "values": {"uncommon": 10.0, "rare": 18.0, "epic": 28.0, "legendary": 45.0}, "format": "🟢+%d 移动速度"}
		]
	else:
		bonus_pool = [
			{"key": "evade_chance", "name": "闪避率", "values": {"uncommon": 0.05, "rare": 0.10, "epic": 0.15, "legendary": 0.25}, "format": "🟢+%d%% 闪避率"},
			{"key": "block_amount", "name": "伤害格挡", "values": {"uncommon": 3.0, "rare": 6.0, "epic": 10.0, "legendary": 20.0}, "format": "🟢+%d 物理格挡"},
			{"key": "speed_bonus", "name": "额外移动速度", "values": {"uncommon": 10.0, "rare": 18.0, "epic": 28.0, "legendary": 45.0}, "format": "🟢+%d 移动速度"},
			{"key": "hp_bonus", "name": "额外生命上限", "values": {"uncommon": 30.0, "rare": 60.0, "epic": 100.0, "legendary": 200.0}, "format": "🟢+%d 生命上限"},
			{"key": "mp_bonus", "name": "额外魔法上限", "values": {"uncommon": 20.0, "rare": 40.0, "epic": 75.0, "legendary": 150.0}, "format": "🟢+%d 魔法上限"}
		]

	var num_bonuses = 0
	if grade == "uncommon": num_bonuses = 1
	elif grade == "rare": num_bonuses = 2
	elif grade == "epic": num_bonuses = 3
	elif grade == "legendary": num_bonuses = 4

	# Shuffle bonus pool
	bonus_pool.shuffle()
	var selected_bonuses = bonus_pool.slice(0, num_bonuses)
	
	var bonus_descs = []
	for b in selected_bonuses:
		var val = b.values[grade]
		if b.key == "crit_chance" or b.key == "lifesteal_percent" or b.key == "evade_chance":
			item_data[b.key] = item_data.get(b.key, 0.0) + val
			bonus_descs.append(b.format % int(val * 100.0))
		else:
			item_data[b.key] = item_data.get(b.key, 0.0) + val
			bonus_descs.append(b.format % int(val))

	var raw_desc = selected_template.description
	var format_args = []
	if base_atk > 0.0: format_args.append(int(final_atk))
	if base_def > 0.0: format_args.append(int(final_def))
	if base_hp > 0.0: format_args.append(int(final_hp))
	if base_speed > 0.0: format_args.append(int(final_speed))

	var desc = raw_desc % format_args
	if not bonus_descs.is_empty():
		desc += "\n附加属性:\n" + "\n".join(bonus_descs)
		
	if selected_template.has("set_name"):
		var set_info = ""
		if selected_template.set_name == "champion":
			set_info = "\n[勇者套装 (Champion)]\n- 2件: 物理伤害提升 15%\n- 3件: 物理暴击率提升 20%"
		elif selected_template.set_name == "shadow":
			set_info = "\n[影武者套装 (Shadow)]\n- 2件: 闪避率提升 15%\n- 3件: 生命吸取提升 15%"
		elif selected_template.set_name == "lava":
			set_info = "\n[熔岩守卫套装 (Lava)]\n- 2件: +150生命上限 & +10防御\n- 3件: 末日怒火 (2秒一周围敌30伤)"
		desc += set_info

	item_data["description"] = desc
	item_data["name"] = prefix + selected_template.name
	
	var base_cost = 40.0
	if selected_template.type == "crest":
		base_cost = 80.0
	item_data["cost"] = int(round(base_cost * cost_mult))

	return item_data

static func spawn_loot_drop(scene_root: Node, pos: Vector2, item_data: Dictionary) -> void:
	var loot_scene = load("res://scenes/item_drop.tscn")
	if loot_scene:
		var drop = loot_scene.instantiate()
		drop.global_position = pos
		drop.set_item_data(item_data)
		scene_root.add_child(drop)
		print("[Loot Dropper] Spawned physical drop: ", item_data.name, " at ", pos)

static func spawn_hit_sparks(scene_root: Node, pos: Vector2) -> void:
	var sparks_scene = load("res://scenes/hit_sparks.tscn")
	if sparks_scene:
		var sparks = sparks_scene.instantiate()
		sparks.global_position = pos
		scene_root.add_child(sparks)

static func roll_purchased_item(shop_item: Dictionary) -> Dictionary:
	var weapons = [
		{"name": "铁木长弓 (Elven Bow)", "type": "weapon", "atk_bonus": 6.0, "description": "+%d 点攻击力。"},
		{"name": "淬毒钢爪 (Poisoned Claws)", "type": "weapon", "atk_bonus": 8.0, "description": "+%d 点攻击力。"},
		{"name": "狂暴之刃 (Furious Blade)", "type": "weapon", "atk_bonus": 10.0, "description": "+%d 点攻击力。"},
		{"name": "勇者之剑 (Champion Sword)", "type": "weapon", "atk_bonus": 12.0, "set_name": "champion", "set_item_id": "champion_sword", "description": "+%d 物理攻击。"},
		{"name": "影刃匕首 (Shadow Dagger)", "type": "weapon", "atk_bonus": 9.0, "set_name": "shadow", "set_item_id": "shadow_dagger", "description": "+%d 物理攻击。"},
		{"name": "熔岩大剑 (Lava Greatsword)", "type": "weapon", "atk_bonus": 14.0, "set_name": "lava", "set_item_id": "lava_greatsword", "description": "+%d 物理攻击。"}
	]
	var armors = [
		{"name": "锁子硬甲 (Chainmail)", "type": "armor", "def_bonus": 2.0, "hp_bonus": 50.0, "description": "+%d 护甲, +%d 生命值。"},
		{"name": "皮质圆盾 (Leather Shield)", "type": "armor", "def_bonus": 3.0, "description": "+%d 点护甲保护。"},
		{"name": "精钢护板 (Steel Plate)", "type": "armor", "def_bonus": 4.0, "hp_bonus": 100.0, "description": "+%d 护甲, +%d 生命值。"},
		{"name": "勇者胸甲 (Champion Chestplate)", "type": "armor", "def_bonus": 3.0, "hp_bonus": 60.0, "set_name": "champion", "set_item_id": "champion_breastplate", "description": "+%d 物理防护, +%d 生命上限。"},
		{"name": "影之皮甲 (Shadow Leather)", "type": "armor", "def_bonus": 2.0, "hp_bonus": 45.0, "set_name": "shadow", "set_item_id": "shadow_leather", "description": "+%d 物理防护, +%d 生命上限。"},
		{"name": "熔岩重铠 (Lava Iron Armor)", "type": "armor", "def_bonus": 4.5, "hp_bonus": 110.0, "set_name": "lava", "set_item_id": "lava_iron_armor", "description": "+%d 物理防护, +%d 生命上限。"}
	]
	var boots = [
		{"name": "野外软鞋 (Wild Boots)", "type": "boots", "speed_bonus": 30.0, "description": "+%d 点移动速度。"},
		{"name": "飞燕战靴 (Swift Boots)", "type": "boots", "speed_bonus": 50.0, "description": "+%d 点移动速度。"},
		{"name": "影舞战靴 (Shadow Boots)", "type": "boots", "speed_bonus": 55.0, "set_name": "shadow", "set_item_id": "shadow_boots", "description": "+%d 点移动速度。"}
	]
	var crests = [
		{"name": "猎手徽章 (Hunter's Sigil)", "type": "crest", "atk_bonus": 8.0, "hp_bonus": 80.0, "speed_bonus": 25.0, "description": "+%d 攻击, +%d 生命, +%d 速度。"},
		{"name": "勇者徽章 (Champion Sigil)", "type": "crest", "atk_bonus": 6.0, "hp_bonus": 40.0, "set_name": "champion", "set_item_id": "champion_sigil", "description": "+%d 攻击力, +%d 生命值。"},
		{"name": "火山徽章 (Volcanic Sigil)", "type": "crest", "atk_bonus": 7.0, "hp_bonus": 70.0, "set_name": "lava", "set_item_id": "lava_sigil", "description": "+%d 攻击力, +%d 生命值。"}
	]

	var template = {}
	var type = shop_item.get("type", "")
	var raw_name = shop_item.get("name", "")
	
	raw_name = raw_name.replace("🟠[传说] ", "")
	raw_name = raw_name.replace("🟣[史诗] ", "")
	raw_name = raw_name.replace("🔵[精良] ", "")
	raw_name = raw_name.replace("🟢[优秀] ", "")
	raw_name = raw_name.replace("⚪[普通] ", "")
	
	var list_to_search = []
	if type == "weapon": list_to_search = weapons
	elif type == "armor": list_to_search = armors
	elif type == "boots": list_to_search = boots
	elif type == "crest": list_to_search = crests
	
	for t in list_to_search:
		if t.name == raw_name:
			template = t.duplicate()
			break
			
	if template.is_empty():
		return shop_item.duplicate()
		
	var grade = shop_item.get("grade", "common")
	var prefix = ""
	var stat_mult = 1.0
	
	if grade == "legendary":
		prefix = "🟠[传说] "
		stat_mult = 3.5
	elif grade == "epic":
		prefix = "🟣[史诗] "
		stat_mult = 2.2
	elif grade == "rare":
		prefix = "🔵[精良] "
		stat_mult = 1.6
	elif grade == "uncommon":
		prefix = "🟢[优秀] "
		stat_mult = 1.3
	else:
		prefix = "⚪[普通] "
		stat_mult = 0.5
		
	var rolled_item = {
		"type": template.type,
		"grade": grade
	}
	if template.has("set_name"):
		rolled_item["set_name"] = template.set_name
		rolled_item["set_item_id"] = template.set_item_id

	var base_atk = template.get("atk_bonus", 0.0)
	var base_def = template.get("def_bonus", 0.0)
	var base_hp = template.get("hp_bonus", 0.0)
	var base_speed = template.get("speed_bonus", 0.0)

	var final_atk = round(base_atk * stat_mult)
	var final_def = round(base_def * stat_mult)
	var final_hp = round(base_hp * stat_mult)
	var final_speed = round(base_speed * stat_mult)

	if base_atk > 0.0: rolled_item["atk_bonus"] = final_atk
	if base_def > 0.0: rolled_item["def_bonus"] = final_def
	if base_hp > 0.0: rolled_item["hp_bonus"] = final_hp
	if base_speed > 0.0: rolled_item["speed_bonus"] = final_speed
	
	if template.has("lifesteal_percent"):
		rolled_item["lifesteal_percent"] = template["lifesteal_percent"]

	# Shuffling and adding random bonus stats if grade is green or above!
	var bonus_pool = []
	if template.type == "weapon":
		bonus_pool = [
			{"key": "crit_chance", "name": "暴击率", "values": {"uncommon": 0.05, "rare": 0.10, "epic": 0.15, "legendary": 0.25}, "format": "🟢+%d%% 暴击率"},
			{"key": "lifesteal_percent", "name": "生命吸取", "values": {"uncommon": 0.05, "rare": 0.10, "epic": 0.15, "legendary": 0.25}, "format": "🟢+%d%% 生命吸取"},
			{"key": "atk_bonus", "name": "额外攻击力", "values": {"uncommon": 3.0, "rare": 6.0, "epic": 10.0, "legendary": 18.0}, "format": "🟢+%d 物理攻击"},
			{"key": "speed_bonus", "name": "额外移动速度", "values": {"uncommon": 10.0, "rare": 18.0, "epic": 28.0, "legendary": 45.0}, "format": "🟢+%d 移动速度"}
		]
	else:
		bonus_pool = [
			{"key": "evade_chance", "name": "闪避率", "values": {"uncommon": 0.05, "rare": 0.10, "epic": 0.15, "legendary": 0.25}, "format": "🟢+%d%% 闪避率"},
			{"key": "block_amount", "name": "伤害格挡", "values": {"uncommon": 3.0, "rare": 6.0, "epic": 10.0, "legendary": 20.0}, "format": "🟢+%d 物理格挡"},
			{"key": "speed_bonus", "name": "额外移动速度", "values": {"uncommon": 10.0, "rare": 18.0, "epic": 28.0, "legendary": 45.0}, "format": "🟢+%d 移动速度"},
			{"key": "hp_bonus", "name": "额外生命上限", "values": {"uncommon": 30.0, "rare": 60.0, "epic": 100.0, "legendary": 200.0}, "format": "🟢+%d 生命上限"},
			{"key": "mp_bonus", "name": "额外魔法上限", "values": {"uncommon": 20.0, "rare": 40.0, "epic": 75.0, "legendary": 150.0}, "format": "🟢+%d 魔法上限"}
		]

	var num_bonuses = 0
	if grade == "uncommon": num_bonuses = 1
	elif grade == "rare": num_bonuses = 2
	elif grade == "epic": num_bonuses = 3
	elif grade == "legendary": num_bonuses = 4

	bonus_pool.shuffle()
	var selected_bonuses = bonus_pool.slice(0, num_bonuses)
	
	var bonus_descs = []
	for b in selected_bonuses:
		var val = b.values[grade]
		if b.key == "crit_chance" or b.key == "lifesteal_percent" or b.key == "evade_chance":
			rolled_item[b.key] = rolled_item.get(b.key, 0.0) + val
			bonus_descs.append(b.format % int(val * 100.0))
		else:
			rolled_item[b.key] = rolled_item.get(b.key, 0.0) + val
			bonus_descs.append(b.format % int(val))

	var raw_desc = template.description
	var format_args = []
	if base_atk > 0.0: format_args.append(int(final_atk))
	if base_def > 0.0: format_args.append(int(final_def))
	if base_hp > 0.0: format_args.append(int(final_hp))
	if base_speed > 0.0: format_args.append(int(final_speed))

	var desc = raw_desc % format_args
	if not bonus_descs.is_empty():
		desc += "\n附加属性:\n" + "\n".join(bonus_descs)
		
	if template.has("set_name"):
		var set_info = ""
		if template.set_name == "champion":
			set_info = "\n[勇者套装 (Champion)]\n- 2件: 物理伤害提升 15%\n- 3件: 物理暴击率提升 20%"
		elif template.set_name == "shadow":
			set_info = "\n[影武者套装 (Shadow)]\n- 2件: 闪避率提升 15%\n- 3件: 生命吸取提升 15%"
		elif template.set_name == "lava":
			set_info = "\n[熔岩守卫套装 (Lava)]\n- 2件: +150生命上限 & +10防御\n- 3件: 末日怒火 (2秒一周围敌30伤)"
		desc += set_info

	rolled_item["description"] = desc
	rolled_item["name"] = prefix + template.name
	rolled_item["cost"] = shop_item.get("cost", 50)
	
	return rolled_item

