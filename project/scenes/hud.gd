extends CanvasLayer

const SynthAudio = preload("res://scenes/synth_audio.gd")
const SaveSystem = preload("res://scenes/save_system.gd")

@onready var hp_bar = $Control/BottomBar/Panel/HPBar
@onready var mp_bar = $Control/BottomBar/Panel/MPBar
@onready var xp_bar = $Control/BottomBar/Panel/XPBar
@onready var hp_lbl = $Control/BottomBar/Panel/HPBar/Label
@onready var mp_lbl = $Control/BottomBar/Panel/MPBar/Label
@onready var stats_lbl = $Control/BottomBar/Panel/StatsLabel
@onready var lvl_lbl = $Control/BottomBar/Panel/LevelLabel

@onready var inv_grid = $Control/BottomBar/Panel/InventoryGrid
@onready var btn_q = $Control/BottomBar/Panel/Skills/SlotQ/BtnQ
@onready var btn_w = $Control/BottomBar/Panel/Skills/SlotW/BtnW
@onready var btn_q_plus = $Control/BottomBar/Panel/Skills/SlotQ/BtnQPlus
@onready var btn_w_plus = $Control/BottomBar/Panel/Skills/SlotW/BtnWPlus
@onready var btn_e = $Control/BottomBar/Panel/Skills/SlotE/BtnE
@onready var btn_e_plus = $Control/BottomBar/Panel/Skills/SlotE/BtnEPlus

@onready var str_lbl = $Control/BottomBar/Panel/AttrsContainer/StrContainer/StrLabel
@onready var btn_str_plus = $Control/BottomBar/Panel/AttrsContainer/StrContainer/BtnStrPlus
@onready var agi_lbl = $Control/BottomBar/Panel/AttrsContainer/AgiContainer/AgiLabel
@onready var btn_agi_plus = $Control/BottomBar/Panel/AttrsContainer/AgiContainer/BtnAgiPlus
@onready var int_lbl = $Control/BottomBar/Panel/AttrsContainer/IntContainer/IntLabel
@onready var btn_int_plus = $Control/BottomBar/Panel/AttrsContainer/IntContainer/BtnIntPlus
@onready var skill_pts_lbl = $Control/BottomBar/Panel/SkillPointsLabel

@onready var game_over_screen = $Control/GameOverScreen
@onready var victory_screen = $Control/VictoryScreen
@onready var btn_next_stage = $Control/VictoryScreen/VBox/BtnNextStage
@onready var game_over_menu_btn = $Control/GameOverScreen/VBox/BtnMenu
@onready var victory_menu_btn = $Control/VictoryScreen/VBox/BtnMenu

@onready var gold_lbl = $Control/BottomBar/Panel/GoldLabel
@onready var shop_panel = $Control/ShopPanel
@onready var shop_gold_lbl = $Control/ShopPanel/ShopGoldLabel
@onready var btn_shop_close = $Control/ShopPanel/BtnClose
@onready var btn_buy1 = $Control/ShopPanel/ItemsContainer/Item1/VBox/BtnBuy1
@onready var btn_buy2 = $Control/ShopPanel/ItemsContainer/Item2/VBox/BtnBuy2
@onready var btn_buy3 = $Control/ShopPanel/ItemsContainer/Item3/VBox/BtnBuy3
@onready var btn_buy4 = $Control/ShopPanel/ItemsContainer/Item4/VBox/BtnBuy4
@onready var item4_panel = $Control/ShopPanel/ItemsContainer/Item4
@onready var btn_buy5 = $Control/ShopPanel/ItemsContainer/Item5/VBox/BtnBuy5
@onready var btn_revive = $Control/GameOverScreen/VBox/BtnRevive
@onready var btn_revive_spot = $Control/GameOverScreen/VBox/BtnReviveSpot
@onready var shop_status_lbl = $Control/ShopPanel/ShopStatusLabel
@onready var boss_hp_bar_container = $Control/BossHPBar
@onready var boss_name_lbl = $Control/BossHPBar/VBox/BossNameLabel
@onready var boss_hp_bar = $Control/BossHPBar/VBox/HPBar
@onready var boss_hp_lbl = $Control/BossHPBar/VBox/HPBar/Label

var player: CharacterBody2D = null

func _ready():
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if player:
		# Connect signals
		player.connect("hp_changed", Callable(self, "_on_hp_changed"))
		player.connect("mp_changed", Callable(self, "_on_mp_changed"))
		player.connect("xp_changed", Callable(self, "_on_xp_changed"))
		player.connect("level_up", Callable(self, "_on_level_up"))
		player.connect("inventory_changed", Callable(self, "_on_inventory_changed"))
		player.connect("skills_changed", Callable(self, "_on_skills_changed"))
		player.connect("gold_changed", Callable(self, "_on_gold_changed"))
		if player.has_signal("resurrected"):
			player.connect("resurrected", Callable(self, "_on_player_resurrected"))
		
		# Initial state
		_on_hp_changed(player.hp, player.hp, player.get_total_max_hp())
		_on_mp_changed(player.mp, player.mp, player.get_total_max_mp())
		_on_xp_changed(player.get_xp(), player.get_xp_to_next_level())
		_on_level_up(player.level)
		_on_inventory_changed()
		_on_skills_changed()
		_on_gold_changed(player.get_gold())
		
	# GameManager setup
	var gm = get_tree().current_scene.get_node_or_null("GameManager")
	if gm:
		gm.connect("game_victory", Callable(self, "_on_victory"))
		gm.connect("game_over", Callable(self, "_on_game_over"))

	# Inventory button clicks mapping
	for i in range(8):
		var btn = inv_grid.get_child(i)
		btn.pressed.connect(func(): _on_inventory_slot_pressed(i))

	btn_q.pressed.connect(func(): _on_skill_q_pressed())
	btn_w.pressed.connect(func(): _on_skill_w_pressed())
	btn_e.pressed.connect(func(): _on_skill_e_pressed())

	# Connect upgrade button clicks
	btn_str_plus.pressed.connect(func(): _on_upgrade_attribute("strength"))
	btn_agi_plus.pressed.connect(func(): _on_upgrade_attribute("agility"))
	btn_int_plus.pressed.connect(func(): _on_upgrade_attribute("intelligence"))
	btn_q_plus.pressed.connect(func(): _on_learn_skill("Q"))
	btn_w_plus.pressed.connect(func(): _on_learn_skill("W"))
	btn_e_plus.pressed.connect(func(): _on_learn_skill("E"))
	
	# Connect next stage button click
	btn_next_stage.pressed.connect(_on_next_stage_pressed)
	
	if game_over_menu_btn:
		game_over_menu_btn.pressed.connect(_on_return_to_menu_pressed)
	if victory_menu_btn:
		victory_menu_btn.pressed.connect(_on_return_to_menu_pressed)

	# Shop connections
	btn_shop_close.pressed.connect(close_shop_ui)
	btn_buy1.pressed.connect(func(): _on_buy_item_pressed("吸血之刃", 60, {
		"name": "Vampiric Blade",
		"type": "weapon",
		"atk_bonus": 8.0,
		"lifesteal_percent": 0.15,
		"description": "+8 ATK, 15% Lifesteal."
	}))
	btn_buy2.pressed.connect(func(): _on_buy_item_pressed("防御板甲", 50, {
		"name": "Plate Armor",
		"type": "armor",
		"def_bonus": 4.0,
		"hp_bonus": 100.0,
		"description": "+4 DEF, +100 Max HP."
	}))
	btn_buy3.pressed.connect(func(): _on_buy_item_pressed("治疗药水", 15, {
		"name": "Potion of Healing",
		"type": "potion",
		"hp_restore": 150.0,
		"description": "Consumable. Restores 150 HP."
	}))
	btn_buy4.pressed.connect(func(): _on_buy_item_pressed("游侠徽记", 120, {
		"name": "Ranger's Crest",
		"type": "crest",
		"atk_bonus": 15.0,
		"hp_bonus": 200.0,
		"speed_bonus": 40.0,
		"description": "+15 ATK, +200 HP, +40 Speed."
	}))
	btn_buy5.pressed.connect(func(): _on_buy_item_pressed("复活十字架", 80, {
		"name": "Ankh of Reincarnation",
		"type": "ankh",
		"description": "Auto-resurrects you on death."
	}))

	if btn_revive:
		btn_revive.pressed.connect(_on_revive_pressed)
	if btn_revive_spot:
		btn_revive_spot.pressed.connect(_on_revive_spot_pressed)

	var scene_path = get_tree().current_scene.scene_file_path
	if scene_path.contains("stage3"):
		item4_panel.show()
	else:
		item4_panel.hide()



func _process(delta):
	if player:
		# Q Skill Text & Status (Searing Arrows)
		var lvl_q = player.get_skill_q_level()
		if lvl_q == 0:
			btn_q.text = "Q\n未学习"
			btn_q.disabled = true
		else:
			btn_q.text = "Q\n炽热箭\n(Lv %d)" % lvl_q
			btn_q.disabled = false
			
		# W Skill Text & Status (Windwalk)
		var lvl_w = player.get_skill_w_level()
		if lvl_w == 0:
			btn_w.text = "W\n未学习"
			btn_w.disabled = true
		else:
			var cd = player.get_skill_w_cooldown()
			if cd > 0.0:
				btn_w.text = "W\nCD: %.1f\n(Lv %d)" % [cd, lvl_w]
				btn_w.disabled = true
			else:
				btn_w.text = "W\n疾风步\n(Lv %d)" % lvl_w
				btn_w.disabled = false
				
		# E Skill Text & Status (Blink)
		var lvl_e = player.get_skill_e_level()
		if lvl_e == 0:
			btn_e.text = "E\n未学习"
			btn_e.disabled = true
		else:
			var cd = player.get_skill_e_cooldown()
			if cd > 0.0:
				btn_e.text = "E\nCD: %.1f\n(Lv %d)" % [cd, lvl_e]
				btn_e.disabled = true
			else:
				btn_e.text = "E\n闪烁\n(Lv %d)" % lvl_e
				btn_e.disabled = false

	# Dynamic Boss HP Bar
	var boss = get_tree().current_scene.get_node_or_null("Boss")
	if boss and player and not boss.get_is_dead() and player.global_position.distance_to(boss.global_position) < 1000.0:
		boss_hp_bar_container.show()
		boss_name_lbl.text = boss.get_character_name()
		var b_hp = boss.hp
		var b_max_hp = boss.get_total_max_hp()
		boss_hp_bar.max_value = b_max_hp
		boss_hp_bar.value = b_hp
		boss_hp_lbl.text = "HP: %d / %d" % [b_hp, b_max_hp]
	else:
		boss_hp_bar_container.hide()

func _on_hp_changed(old_hp, new_hp, max_hp):
	hp_bar.max_value = max_hp
	hp_bar.value = new_hp
	hp_lbl.text = "HP: %d / %d" % [new_hp, max_hp]
	update_stats_display()

func _on_mp_changed(old_mp, new_mp, max_mp):
	mp_bar.max_value = max_mp
	mp_bar.value = new_mp
	mp_lbl.text = "MP: %d / %d" % [new_mp, max_mp]
	update_stats_display()

func _on_xp_changed(xp, max_xp):
	xp_bar.max_value = max_xp
	xp_bar.value = xp
	xp_bar.get_node("Label").text = "XP: %d / %d" % [xp, max_xp]

func _on_level_up(new_level):
	lvl_lbl.text = "LEVEL: %d" % new_level
	update_stats_display()

func get_item_emoji(item: Dictionary) -> String:
	var item_name = item.get("name", "")
	if item_name.contains("Blade") or item_name.contains("Vampiric"):
		return "⚔️"
	elif item_name.contains("Claws") or item_name.contains("Claw"):
		return "🐾"
	elif item_name.contains("Armor") or item_name.contains("Plate"):
		return "🛡️"
	elif item_name.contains("Boots") or item_name.contains("Speed"):
		return "🥾"
	elif item_name.contains("Potion") or item_name.contains("Healing"):
		return "🧪"
	elif item_name.contains("Crest") or item_name.contains("Ranger"):
		return "🏅"
	elif item_name.contains("Ankh") or item_name.contains("Reincarnation"):
		return "👼"
	return "📦"

func _on_inventory_changed():
	if not player: return
	var inv = player.get_inventory()
	for i in range(8):
		var btn = inv_grid.get_child(i)
		var item = inv[i]
		btn.add_theme_font_size_override("font_size", 18)
		if item and not item.is_empty():
			btn.text = get_item_emoji(item)
			btn.tooltip_text = "%s\n%s" % [item.get("name"), item.get("description", "")]
		else:
			btn.text = ""
			btn.tooltip_text = "Empty Slot"
	update_stats_display()

func _on_skills_changed():
	if not player: return
	
	# Skill Q searing arrows active border/state
	if player.get_skill_q_active():
		btn_q.modulate = Color(1.2, 1.2, 0.8, 1.0)
	else:
		btn_q.modulate = Color(1.0, 1.0, 1.0, 1.0)
		
	# Upgrade buttons visibility logic based on skill points
	var pts = player.get_skill_points()
	skill_pts_lbl.text = "可用点数: %d" % pts
	
	var can_upgrade = pts > 0
	btn_str_plus.visible = can_upgrade
	btn_agi_plus.visible = can_upgrade
	btn_int_plus.visible = can_upgrade
	
	btn_q_plus.visible = can_upgrade and player.get_skill_q_level() < 4
	btn_w_plus.visible = can_upgrade and player.get_skill_w_level() < 4
	btn_e_plus.visible = can_upgrade and player.get_skill_e_level() < 4
	
	update_stats_display()

func update_stats_display():
	if not player: return
	var atk = player.get_total_atk()
	var def = player.get_total_def()
	var str_val = player.strength
	var agi_val = player.agility
	var int_val = player.intelligence
	
	stats_lbl.text = "ATK: %d   DEF: %.1f" % [atk, def]
	str_lbl.text = "STR: %d" % str_val
	agi_lbl.text = "AGI: %d" % agi_val
	int_lbl.text = "INT: %d" % int_val

func get_sell_price(item_name: String) -> int:
	if item_name.contains("Vampiric") or item_name.contains("吸血之刃"):
		return 30
	elif item_name.contains("Plate") or item_name.contains("防御板甲"):
		return 25
	elif item_name.contains("Boots") or item_name.contains("急速之靴"):
		return 22
	elif item_name.contains("Ranger") or item_name.contains("游侠徽记"):
		return 60
	elif item_name.contains("Ankh") or item_name.contains("复活"):
		return 40
	elif item_name.contains("Potion") or item_name.contains("治疗药水"):
		return 7
	elif item_name.contains("Claws") or item_name.contains("攻击之爪"):
		return 15
	return 10 # default fallback

func _on_inventory_slot_pressed(slot_index):
	if player:
		if shop_panel.visible:
			var inv = player.get_inventory()
			if slot_index < inv.size():
				var item = inv[slot_index]
				if item and not item.is_empty():
					var item_name = item.get("name", "")
					var sell_price = get_sell_price(item_name)
					
					# Give gold to player
					player.set_gold(player.get_gold() + sell_price)
					
					# Remove item from inventory
					player.remove_from_inventory(slot_index)
					
					# Play purchase sound or sell sound
					SynthAudio.play_purchase(self)
					
					# Show status message
					_show_shop_status("✓ 已售出: %s，获得 %d 金币" % [item_name, sell_price], Color(0.2, 0.9, 0.2))
					
					# Update hud
					_on_gold_changed(player.get_gold())
					_on_inventory_changed()
		else:
			player.use_item(slot_index)

func _on_skill_q_pressed():
	if player:
		player.toggle_skill_q()

func _on_skill_w_pressed():
	if player:
		player.cast_skill_w()

func _on_skill_e_pressed():
	if player:
		player.cast_skill_e_forward()

func _on_upgrade_attribute(attr_name: String):
	if player:
		player.upgrade_attribute(attr_name)

func _on_learn_skill(skill_name: String):
	if player:
		player.learn_skill(skill_name)

func _on_victory():
	victory_screen.show()
	var current_scene = get_tree().current_scene.scene_file_path
	var btn_restart = victory_screen.get_node("VBox/BtnRestart")
	var label = victory_screen.get_node("VBox/Label")
	
	if current_scene.contains("main.tscn"):
		btn_next_stage.show()
		btn_next_stage.text = "进入第二关 (Stage 2)"
		btn_restart.text = "重玩本关 (Replay)"
	elif current_scene.contains("stage2.tscn"):
		btn_next_stage.show()
		btn_next_stage.text = "进入最终关 (Stage 3)"
		btn_restart.text = "重玩本关 (Replay)"
	else:
		# Stage 3 (Final Stage)
		btn_next_stage.hide()
		if label:
			label.text = "恭喜通关游侠之路！\n(Congratulations! You saved Ranger's Path!)"
			label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.15))
		btn_restart.text = "重新开始游戏 (Restart Game)"

func _on_next_stage_pressed():
	if player:
		SaveSystem.save_game(player)
	var current_scene = get_tree().current_scene.scene_file_path
	if current_scene.contains("main.tscn"):
		get_tree().change_scene_to_file("res://scenes/stage2.tscn")
	elif current_scene.contains("stage2.tscn"):
		get_tree().change_scene_to_file("res://scenes/stage3.tscn")

func _on_game_over():
	game_over_screen.show()

func _on_restart_pressed():
	var gm = get_tree().current_scene.get_node_or_null("GameManager")
	if gm:
		gm.restart_game()

func _on_gold_changed(new_gold: int):
	gold_lbl.text = "金币: %d" % new_gold
	if shop_gold_lbl:
		shop_gold_lbl.text = "您的金币: %d" % new_gold

func open_shop_ui(player_node):
	if player_node:
		player = player_node
	shop_panel.show()
	shop_status_lbl.text = ""
	if player:
		_on_gold_changed(player.get_gold())
		print("[Shop] Opened. Player gold: ", player.get_gold(), " Inventory: ", player.get_inventory())
	else:
		print("[Shop] ERROR: player is null!")

func close_shop_ui():
	shop_panel.hide()

func _on_buy_item_pressed(item_name: String, cost: int, item_data: Dictionary):
	shop_status_lbl.text = ""
	if not player:
		print("[Shop] Buy failed: player is null")
		_show_shop_status("错误：找不到玩家", Color(1, 0.2, 0.2))
		return
	
	var current_gold = player.get_gold()
	print("[Shop] Attempting to buy: ", item_name, " cost: ", cost, " gold: ", current_gold)
	
	if current_gold < cost:
		_show_shop_status("金币不足！(需要 %d 金币，持有 %d)" % [cost, current_gold], Color(1, 0.3, 0.1))
		return
	
	if player.add_to_inventory(item_data):
		player.set_gold(current_gold - cost)
		SynthAudio.play_purchase(self)
		_show_shop_status("✓ 已购买: " + item_name, Color(0.2, 0.9, 0.2))
		print("[Shop] Purchase success: ", item_name, " remaining gold: ", player.get_gold())
	else:
		_show_shop_status("背包已满！（共6格）", Color(1, 0.3, 0.1))
		print("[Shop] Buy failed: inventory full")

func _show_shop_status(msg: String, color: Color):
	shop_status_lbl.text = msg
	shop_status_lbl.add_theme_color_override("font_color", color)
	# Auto-clear after 3 seconds
	var t = get_tree().create_timer(3.0)
	t.timeout.connect(func(): if shop_status_lbl: shop_status_lbl.text = "")

func spawn_error_msg(msg: String):
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_method("spawn_floating_text"):
		main_scene.call("spawn_floating_text", player.global_position + Vector2(0, -30), msg, Color(1.0, 0.1, 0.1))

func _on_revive_pressed():
	if player:
		# Reset GameManager state so future deaths can trigger game over again
		var gm = get_tree().current_scene.get_node_or_null("GameManager")
		if gm:
			gm.reset_game_state()
		player.call("revive_at_start")
		game_over_screen.hide()
		var p_scene = preload("res://scenes/level_up_particles.tscn")
		var p = p_scene.instantiate()
		player.add_child(p)
		SynthAudio.play_heal(self)

func _on_player_resurrected():
	var p_scene = preload("res://scenes/level_up_particles.tscn")
	var p = p_scene.instantiate()
	player.add_child(p)
	SynthAudio.play_heal(self)
	var main_scene = get_tree().current_scene
	if main_scene and main_scene.has_method("spawn_floating_text"):
		main_scene.call("spawn_floating_text", player.global_position + Vector2(0, -30), "👼 复活重生！", Color(0.9, 0.8, 0.15))

func _on_return_to_menu_pressed():
	# Go back to main menu
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_revive_spot_pressed():
	if player:
		# Reset GameManager state so future deaths can trigger game over again
		var gm = get_tree().current_scene.get_node_or_null("GameManager")
		if gm:
			gm.reset_game_state()
		player.call("revive_on_spot")
		game_over_screen.hide()
		var p_scene = preload("res://scenes/level_up_particles.tscn")
		var p = p_scene.instantiate()
		player.add_child(p)
		SynthAudio.play_heal(self)
		
		var main_scene = get_tree().current_scene
		if main_scene and main_scene.has_method("spawn_floating_text"):
			main_scene.call("spawn_floating_text", player.global_position + Vector2(0, -30), "👼 原地复活！", Color(0.15, 0.85, 1.0))
