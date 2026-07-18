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
@onready var btn_r = $Control/BottomBar/Panel/Skills/SlotR/BtnR
@onready var btn_r_plus = $Control/BottomBar/Panel/Skills/SlotR/BtnRPlus
@onready var upgrade_items_container = $Control/ShopPanel/UpgradeScroll/UpgradeItemsContainer

@onready var str_lbl = $Control/BottomBar/Panel/AttrsContainer/StrContainer/StrLabel
@onready var btn_str_plus = $Control/BottomBar/Panel/AttrsContainer/StrContainer/BtnStrPlus
@onready var agi_lbl = $Control/BottomBar/Panel/AttrsContainer/AgiContainer/AgiLabel
@onready var btn_agi_plus = $Control/BottomBar/Panel/AttrsContainer/AgiContainer/BtnAgiPlus
@onready var int_lbl = $Control/BottomBar/Panel/AttrsContainer/IntContainer/IntLabel
@onready var btn_int_plus = $Control/BottomBar/Panel/AttrsContainer/IntContainer/BtnIntPlus
@onready var skill_pts_lbl = $Control/BottomBar/Panel/SkillPointsLabel

@onready var game_over_screen = $Control/GameOverScreen
@onready var victory_screen = $Control/VictoryScreen
@onready var pause_menu = $Control/PauseMenu
@onready var btn_next_stage = $Control/VictoryScreen/VBox/BtnNextStage
@onready var game_over_menu_btn = $Control/GameOverScreen/VBox/BtnMenu
@onready var victory_menu_btn = $Control/VictoryScreen/VBox/BtnMenu

@onready var gold_lbl = $Control/BottomBar/Panel/GoldLabel
@onready var shop_panel = $Control/ShopPanel
@onready var shop_gold_lbl = $Control/ShopPanel/ShopGoldLabel
@onready var btn_shop_close = $Control/ShopPanel/BtnClose
@onready var shop_items_container = $Control/ShopPanel/ShopScroll/ItemsContainer
@onready var btn_revive = $Control/GameOverScreen/VBox/BtnRevive
@onready var btn_revive_spot = $Control/GameOverScreen/VBox/BtnReviveSpot
@onready var shop_status_lbl = $Control/ShopPanel/ShopStatusLabel
@onready var boss_hp_bar_container = $Control/BossHPBar
@onready var btn_open_talents = $Control/BottomBar/Panel/BtnOpenTalents
@onready var talent_panel = $Control/TalentPanel
@onready var talent_points_lbl = $Control/TalentPanel/PointsLabel
@onready var talent_rows_container = $Control/TalentPanel/RowsContainer
@onready var btn_talent_close = $Control/TalentPanel/BtnClose
@onready var boss_name_lbl = $Control/BossHPBar/VBox/BossNameLabel
@onready var boss_hp_bar = $Control/BossHPBar/VBox/HPBar
@onready var boss_hp_lbl = $Control/BossHPBar/VBox/HPBar/Label

var player: CharacterBody2D = null
var _is_ready = false
var active_quests: Array = []
var boss_notice_panel: PanelContainer = null

var base_shop_items = [
	{
		"name": "治疗药水",
		"cost": 15,
		"data": {
			"name": "Potion of Healing",
			"type": "potion",
			"hp_restore": 150.0,
			"description": "Consumable. Restores 150 HP."
		}
	},
	{
		"name": "复活十字架",
		"cost": 80,
		"data": {
			"name": "Ankh of Reincarnation",
			"type": "ankh",
			"description": "Auto-resurrects you on death."
		}
	}
]

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
		init_quests()
		
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
	btn_r.pressed.connect(func(): _on_skill_r_pressed())

	# Connect upgrade button clicks
	btn_str_plus.pressed.connect(func(): _on_upgrade_attribute("strength"))
	btn_agi_plus.pressed.connect(func(): _on_upgrade_attribute("agility"))
	btn_int_plus.pressed.connect(func(): _on_upgrade_attribute("intelligence"))
	btn_q_plus.pressed.connect(func(): _on_learn_skill("Q"))
	btn_w_plus.pressed.connect(func(): _on_learn_skill("W"))
	btn_e_plus.pressed.connect(func(): _on_learn_skill("E"))
	btn_r_plus.pressed.connect(func(): _on_learn_skill("R"))
	
	# Connect next stage button click
	btn_next_stage.pressed.connect(_on_next_stage_pressed)
	
	if game_over_menu_btn:
		game_over_menu_btn.pressed.connect(_on_return_to_menu_pressed)
	if victory_menu_btn:
		victory_menu_btn.pressed.connect(_on_return_to_menu_pressed)

	# Shop connections
	btn_shop_close.pressed.connect(close_shop_ui)

	# Talent connections
	btn_open_talents.pressed.connect(func():
		if talent_panel.visible:
			close_talent_ui()
		else:
			open_talent_ui()
	)
	btn_talent_close.pressed.connect(close_talent_ui)

	if btn_revive:
		btn_revive.pressed.connect(_on_revive_pressed)
	if btn_revive_spot:
		btn_revive_spot.pressed.connect(_on_revive_spot_pressed)

	# Cinematic Fade In
	var fade = get_node_or_null("Control/FadeOverlay")
	if fade:
		fade.color.a = 1.0
		fade.show()
		var tween = create_tween()
		tween.tween_property(fade, "color:a", 0.0, 0.6)
		tween.tween_callback(fade.hide)

	TranslationManager.locale_changed.connect(refresh_translations)
	refresh_translations()
	
	var instructions = get_node_or_null("Control/Instructions")
	if instructions:
		instructions.visible = false
		
	setup_boss_defeated_notice()
	_is_ready = true

func _process(delta):
	if player:
		# Q Skill Text & Status (Searing Arrows)
		var lvl_q = player.get_skill_q_level()
		if lvl_q == 0:
			btn_q.text = "Q\n" + TranslationManager.t("SKILL_NOT_LEARNED")
			btn_q.disabled = true
		else:
			btn_q.text = "Q\n" + TranslationManager.t("SKILL_Q_NAME") + "\n(Lv %d)" % lvl_q
			btn_q.disabled = false
			
		# W Skill Text & Status (Windwalk)
		var lvl_w = player.get_skill_w_level()
		if lvl_w == 0:
			btn_w.text = "W\n" + TranslationManager.t("SKILL_NOT_LEARNED")
			btn_w.disabled = true
		else:
			var cd = player.get_skill_w_cooldown()
			if cd > 0.0:
				btn_w.text = "W\nCD: %.1f\n(Lv %d)" % [cd, lvl_w]
				btn_w.disabled = true
			else:
				btn_w.text = "W\n" + TranslationManager.t("SKILL_W_NAME") + "\n(Lv %d)" % lvl_w
				btn_w.disabled = false
				
		# E Skill Text & Status (Blink)
		var lvl_e = player.get_skill_e_level()
		if lvl_e == 0:
			btn_e.text = "E\n" + TranslationManager.t("SKILL_NOT_LEARNED")
			btn_e.disabled = true
		else:
			var cd = player.get_skill_e_cooldown()
			if cd > 0.0:
				btn_e.text = "E\nCD: %.1f\n(Lv %d)" % [cd, lvl_e]
				btn_e.disabled = true
			else:
				btn_e.text = "E\n" + TranslationManager.t("SKILL_E_NAME") + "\n(Lv %d)" % lvl_e
				btn_e.disabled = false

		# R Skill Text & Status (Arrow Rain)
		var lvl_r = player.get_skill_r_level()
		if lvl_r == 0:
			btn_r.text = "R\n" + TranslationManager.t("SKILL_NOT_LEARNED")
			btn_r.disabled = true
		else:
			var cd = player.get_skill_r_cooldown()
			if cd > 0.0:
				btn_r.text = "R\nCD: %.1f\n(Lv %d)" % [cd, lvl_r]
				btn_r.disabled = true
			else:
				btn_r.text = "R\n" + TranslationManager.t("SKILL_R_NAME") + "\n(Lv %d)" % lvl_r
				btn_r.disabled = false

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
	if new_hp < old_hp:
		trigger_damage_flash()

func trigger_damage_flash():
	var flash = get_node_or_null("Control/DamageFlash")
	if not flash: return
	flash.color.a = 0.35
	var tween = create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.45).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

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
	_on_skills_changed()  # Refresh skill points counter and upgrade buttons
	update_stats_display()
	if _is_ready and player:
		SaveSystem.save_game(player)

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
			# Color slots based on rarity grade
			var grade = item.get("grade", "common")
			if grade == "uncommon":
				btn.modulate = Color(0.4, 1.0, 0.4)
			elif grade == "rare":
				btn.modulate = Color(0.4, 0.7, 1.0)
			elif grade == "epic":
				btn.modulate = Color(0.9, 0.4, 1.0)
			elif grade == "legendary":
				btn.modulate = Color(1.0, 0.7, 0.1)
			else:
				btn.modulate = Color(1.0, 1.0, 1.0)
		else:
			btn.text = ""
			btn.tooltip_text = "Empty Slot"
			btn.modulate = Color(1.0, 1.0, 1.0)
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
	skill_pts_lbl.text = TranslationManager.t("HUD_SKILL_POINTS") + str(pts)
	
	var can_upgrade = pts > 0
	btn_str_plus.visible = can_upgrade
	btn_agi_plus.visible = can_upgrade
	btn_int_plus.visible = can_upgrade
	
	btn_q_plus.visible = can_upgrade and player.get_skill_q_level() < 4
	btn_w_plus.visible = can_upgrade and player.get_skill_w_level() < 4
	btn_e_plus.visible = can_upgrade and player.get_skill_e_level() < 4
	btn_r_plus.visible = can_upgrade and player.get_skill_r_level() < 4
	
	update_stats_display()
	if talent_panel.visible:
		populate_talents()

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

func get_sell_price_for_item(item: Dictionary) -> int:
	if item.has("cost"):
		return int(floor(item.cost * 0.5))
	
	# Fallback based on name patterns
	var item_name = item.get("name", "")
	var base_cost = 50
	
	var grade = item.get("grade", "common")
	if grade == "common":
		base_cost = 40 * 0.4
	elif grade == "uncommon":
		base_cost = 40 * 1.5
	elif grade == "rare":
		base_cost = 40 * 2.0
	elif grade == "epic":
		base_cost = 40 * 3.0
	elif grade == "legendary":
		base_cost = 40 * 5.0
		
	if item_name.contains("Vampiric") or item_name.contains("吸血之刃"):
		base_cost = 60
	elif item_name.contains("Plate") or item_name.contains("防御板甲"):
		base_cost = 50
	elif item_name.contains("Boots") or item_name.contains("急速之靴") or item_name.contains("Wild") or item_name.contains("野外软鞋"):
		base_cost = 40
	elif item_name.contains("Ranger") or item_name.contains("游侠徽记"):
		base_cost = 120
	elif item_name.contains("Ankh") or item_name.contains("复活") or item_name.contains("Reincarnation"):
		base_cost = 80
	elif item_name.contains("Potion") or item_name.contains("治疗药水"):
		base_cost = 15
	elif item_name.contains("Claws") or item_name.contains("攻击之爪") or item_name.contains("钢爪"):
		base_cost = 40
		
	# Apply common nerf to fallback equipment costs
	if grade == "common" and not (item_name.contains("Potion") or item_name.contains("治疗药水")):
		if base_cost > 15:
			base_cost = base_cost * 0.4
			
	return int(floor(base_cost * 0.5))

func _on_inventory_slot_pressed(slot_index):
	if player:
		if shop_panel.visible:
			var inv = player.get_inventory()
			if slot_index < inv.size():
				var item = inv[slot_index]
				if item and not item.is_empty():
					var item_name = item.get("name", "")
					var sell_price = get_sell_price_for_item(item)
					
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
					populate_upgrade_station()
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

func _on_skill_r_pressed():
	if player:
		player.cast_skill_r(player.get_global_mouse_position())

func _on_upgrade_attribute(attr_name: String):
	if player:
		player.upgrade_attribute(attr_name)
		SaveSystem.save_game(player)

func _on_learn_skill(skill_name: String):
	if player:
		player.learn_skill(skill_name)
		SaveSystem.save_game(player)

func recycle_inventory_on_victory() -> void:
	if not player: return
	var inv = player.get_inventory()
	var total_gold_gained = 0
	var recycled_items = []
	for i in range(inv.size()):
		var item = inv[i]
		if item and not item.is_empty():
			var sell_price = get_sell_price_for_item(item)
			total_gold_gained += sell_price
			recycled_items.append(item.get("name", "Unknown"))
			player.remove_from_inventory(i)
	
	if total_gold_gained > 0:
		player.set_gold(player.get_gold() + total_gold_gained)
		print("[Victory Recycle] Recycled items: ", recycled_items, " Gained gold: ", total_gold_gained)
		_on_gold_changed(player.get_gold())
		_on_inventory_changed()
		
		var main_scene = get_tree().current_scene
		if main_scene and main_scene.has_method("spawn_floating_text"):
			main_scene.call("spawn_floating_text", player.global_position + Vector2(0, -60), "💰 通关装备回收: +%d 金币！" % total_gold_gained, Color(0.9, 0.8, 0.15))

func _on_victory():
	recycle_inventory_on_victory()
	victory_screen.show()
	var current_scene = get_tree().current_scene.scene_file_path
	var btn_restart = victory_screen.get_node("VBox/BtnRestart")
	var label = victory_screen.get_node("VBox/Label")
	
	if player:
		if current_scene.contains("main.tscn"):
			SaveSystem.save_game(player, 2)
		elif current_scene.contains("stage2.tscn"):
			SaveSystem.save_game(player, 3)
		elif current_scene.contains("stage3.tscn"):
			SaveSystem.save_game(player, 4)
		elif current_scene.contains("stage4.tscn"):
			SaveSystem.save_game(player, 5)
		elif current_scene.contains("stage5.tscn"):
			SaveSystem.save_game(player, 6)
		else:
			SaveSystem.save_game(player, 7)
	
	if current_scene.contains("main.tscn"):
		btn_next_stage.show()
		btn_next_stage.text = TranslationManager.t("MENU_STAGE_ENTER") + ": " + TranslationManager.t("STAGE_2")
		btn_restart.text = TranslationManager.t("HUD_PLAY_AGAIN")
	elif current_scene.contains("stage2.tscn"):
		btn_next_stage.show()
		btn_next_stage.text = TranslationManager.t("MENU_STAGE_ENTER") + ": " + TranslationManager.t("STAGE_3")
		btn_restart.text = TranslationManager.t("HUD_PLAY_AGAIN")
	elif current_scene.contains("stage3.tscn"):
		btn_next_stage.show()
		btn_next_stage.text = TranslationManager.t("MENU_STAGE_ENTER") + ": " + TranslationManager.t("STAGE_4")
		btn_restart.text = TranslationManager.t("HUD_PLAY_AGAIN")
	elif current_scene.contains("stage4.tscn"):
		btn_next_stage.show()
		btn_next_stage.text = TranslationManager.t("MENU_STAGE_ENTER") + ": " + TranslationManager.t("STAGE_5")
		btn_restart.text = TranslationManager.t("HUD_PLAY_AGAIN")
	elif current_scene.contains("stage5.tscn"):
		btn_next_stage.show()
		btn_next_stage.text = TranslationManager.t("MENU_STAGE_ENTER") + ": " + TranslationManager.t("STAGE_6")
		btn_restart.text = TranslationManager.t("HUD_PLAY_AGAIN")
	else:
		# Stage 6 (Final Stage)
		btn_next_stage.hide()
		if label:
			label.text = TranslationManager.t("FINAL_STAGE_CONGRATS")
			label.add_theme_color_override("font_color", Color(0.9, 0.8, 0.15))
		btn_restart.text = TranslationManager.t("HUD_RESTART_GAME")

func _on_next_stage_pressed():
	var current_scene = get_tree().current_scene.scene_file_path
	if player:
		if current_scene.contains("main.tscn"):
			SaveSystem.save_game(player, 2)
		elif current_scene.contains("stage2.tscn"):
			SaveSystem.save_game(player, 3)
		elif current_scene.contains("stage3.tscn"):
			SaveSystem.save_game(player, 4)
		elif current_scene.contains("stage4.tscn"):
			SaveSystem.save_game(player, 5)
		elif current_scene.contains("stage5.tscn"):
			SaveSystem.save_game(player, 6)
		else:
			SaveSystem.save_game(player)

	# Determine target scene
	var target_scene := ""
	if current_scene.contains("main.tscn"):
		target_scene = "res://scenes/stage2.tscn"
	elif current_scene.contains("stage2.tscn"):
		target_scene = "res://scenes/stage3.tscn"
	elif current_scene.contains("stage3.tscn"):
		target_scene = "res://scenes/stage4.tscn"
	elif current_scene.contains("stage4.tscn"):
		target_scene = "res://scenes/stage5.tscn"
	elif current_scene.contains("stage5.tscn"):
		target_scene = "res://scenes/stage6.tscn"

	if target_scene.is_empty(): return

	# Cinematic Fade Out then change scene
	var fade = get_node_or_null("Control/FadeOverlay")
	if fade:
		fade.color.a = 0.0
		fade.show()
		var tween = create_tween()
		tween.tween_property(fade, "color:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.tween_callback(func(): get_tree().change_scene_to_file(target_scene))
	else:
		get_tree().change_scene_to_file(target_scene)

func _on_game_over():
	game_over_screen.show()

func _on_restart_pressed():
	get_tree().paused = false
	var gm = get_tree().current_scene.get_node_or_null("GameManager")
	if gm:
		gm.restart_game()
func _on_gold_changed(new_gold: int):
	gold_lbl.text = TranslationManager.t("HUD_GOLD") + str(new_gold)
	if shop_gold_lbl:
		shop_gold_lbl.text = TranslationManager.t("HUD_GOLD_HELD") % new_gold

func open_shop_ui(player_node):
	if player_node:
		player = player_node
	populate_shop()
	populate_upgrade_station()
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
		
	if item_data.get("type", "") in ["weapon", "armor", "boots", "crest"]:
		var owned = false
		for slot in player.get_inventory():
			if slot and not slot.is_empty() and slot.get("name", "") == item_name:
				owned = true
				break
		if owned:
			_show_shop_status("您已拥有该装备！", Color(1, 0.3, 0.1))
			return
	
	var item_to_add = item_data
	if item_data.get("type", "") in ["weapon", "armor", "boots", "crest"]:
		item_to_add = SaveSystem.roll_purchased_item(item_data)
		
	if player.add_to_inventory(item_to_add):
		player.set_gold(current_gold - cost)
		SynthAudio.play_purchase(self)
		_show_shop_status("✓ 已购买: " + TranslationManager.t(item_to_add.get("name", "")), Color(0.2, 0.9, 0.2))
		feed_purchase(item_data.get("name", ""))
		print("[Shop] Purchase success: ", item_name, " remaining gold: ", player.get_gold())
		SaveSystem.save_game(player)
		populate_upgrade_station()
		populate_shop()
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
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _input(event):
	if event.is_action_pressed("ui_cancel"): # ESC key maps to ui_cancel by default
		if game_over_screen.visible or victory_screen.visible:
			return
		if talent_panel.visible:
			close_talent_ui()
			get_viewport().set_input_as_handled()
			return
		if shop_panel.visible:
			close_shop_ui()
			get_viewport().set_input_as_handled()
			return
		if pause_menu.visible:
			_on_resume_pressed()
		else:
			get_tree().paused = true
			pause_menu.show()
			
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_K:
			if talent_panel.visible:
				close_talent_ui()
			else:
				open_talent_ui()
			get_viewport().set_input_as_handled()

func _on_resume_pressed():
	get_tree().paused = false
	pause_menu.hide()

func _on_save_pressed():
	if player:
		SaveSystem.save_game(player)
		var main_scene = get_tree().current_scene
		if main_scene and main_scene.has_method("spawn_floating_text"):
			main_scene.call("spawn_floating_text", player.global_position + Vector2(0, -30), "💾 游戏已手动保存！", Color(0.2, 0.9, 0.2))

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

func populate_shop():
	# Clear existing dynamic items
	for child in shop_items_container.get_children():
		child.queue_free()
		
	# Build catalog: base items + unlocked shop items
	var catalog = []
	catalog.append_array(base_shop_items)
	
	for item in SaveSystem.unlocked_shop_items:
		var found = false
		for cat in catalog:
			if cat.name == item.get("name", ""):
				found = true
				break
		if not found:
			catalog.append({
				"name": item.get("name"),
				"cost": item.get("cost", 50),
				"data": item
			})
			
	# Sort catalog: quality/grade descending, then category type descending
	catalog.sort_custom(func(a, b):
		var grade_a = a.data.get("grade", "common")
		var grade_b = b.data.get("grade", "common")
		
		var w_grade_a = 5 if grade_a == "legendary" else (4 if grade_a == "epic" else (3 if grade_a == "rare" else (2 if grade_a == "uncommon" else 1)))
		var w_grade_b = 5 if grade_b == "legendary" else (4 if grade_b == "epic" else (3 if grade_b == "rare" else (2 if grade_b == "uncommon" else 1)))
		
		if w_grade_a != w_grade_b:
			return w_grade_a > w_grade_b
			
		var type_a = a.data.get("type", "")
		var type_b = b.data.get("type", "")
		
		var w_type_a = 6 if type_a == "weapon" else (5 if type_a == "armor" else (4 if type_a == "boots" else (3 if type_a == "crest" else (2 if type_a == "potion" else 1))))
		var w_type_b = 6 if type_b == "weapon" else (5 if type_b == "armor" else (4 if type_b == "boots" else (3 if type_b == "crest" else (2 if type_b == "potion" else 1))))
		
		if w_type_a != w_type_b:
			return w_type_a > w_type_b
			
		return a.name < b.name
	)
			
	# Instantiate shop panels dynamically — skip common (white) gear
	for item in catalog:
		var item_grade = item.data.get("grade", "common")
		if item_grade == "common" and item.data.get("type", "") not in ["potion", "ankh"]:
			continue
		var panel = Panel.new()
		panel.custom_minimum_size = Vector2(150, 230)
		
		# Margin container for clean padding
		var margin = MarginContainer.new()
		margin.layout_mode = 1
		margin.anchors_preset = Control.PRESET_FULL_RECT
		margin.add_theme_constant_override("margin_left", 8)
		margin.add_theme_constant_override("margin_right", 8)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_bottom", 8)
		panel.add_child(margin)
		
		var vbox = VBoxContainer.new()
		vbox.layout_mode = 2
		vbox.add_theme_constant_override("separation", 8)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		margin.add_child(vbox)
		
		# Name label
		var name_lbl = Label.new()
		name_lbl.text = TranslationManager.t(item.name)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_lbl.add_theme_font_size_override("font_size", 12)
		
		# Color name label based on rarity grade
		var grade = item.data.get("grade", "common")
		if grade == "uncommon":
			name_lbl.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))
		elif grade == "rare":
			name_lbl.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0))
		elif grade == "epic":
			name_lbl.add_theme_color_override("font_color", Color(0.8, 0.3, 1.0))
		elif grade == "legendary":
			name_lbl.add_theme_color_override("font_color", Color(1.0, 0.5, 0.0))
		vbox.add_child(name_lbl)
		
		# Description label
		var desc_lbl = Label.new()
		var type = item.data.get("type", "")
		if type in ["weapon", "armor", "boots", "crest"]:
			var shelf_desc = TranslationManager.t("SHOP_SHELF_RANDOM_STATS")
			if item.data.has("set_name"):
				var set_name = item.data.get("set_name", "")
				if set_name == "champion":
					shelf_desc += "\n" + TranslationManager.t("SET_CHAMPION")
				elif set_name == "shadow":
					shelf_desc += "\n" + TranslationManager.t("SET_SHADOW")
				elif set_name == "lava":
					shelf_desc += "\n" + TranslationManager.t("SET_LAVA")
			desc_lbl.text = shelf_desc
		else:
			desc_lbl.text = TranslationManager.t(item.data.get("description", ""))
		desc_lbl.custom_minimum_size = Vector2(0, 80)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_lbl.add_theme_font_size_override("font_size", 10)
		desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		vbox.add_child(desc_lbl)
		
		# Cost label
		var cost_lbl = Label.new()
		cost_lbl.text = TranslationManager.t("SHOP_ITEM_COST") % item.cost
		cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_lbl.add_theme_font_size_override("font_size", 11)
		cost_lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.15))
		vbox.add_child(cost_lbl)
		
		# Buy button
		var btn_buy = Button.new()
		btn_buy.custom_minimum_size = Vector2(0, 32)
		
		var already_owned = false
		if player and item.data.get("type", "") in ["weapon", "armor", "boots", "crest"]:
			for slot in player.get_inventory():
				if slot and not slot.is_empty() and slot.get("name", "") == item.name:
					already_owned = true
					break
					
		if already_owned:
			btn_buy.text = TranslationManager.t("SHOP_OWNED")
			btn_buy.disabled = true
		else:
			btn_buy.text = TranslationManager.t("SHOP_BUY_BTN")
			btn_buy.pressed.connect(func(): _on_buy_item_pressed(item.name, item.cost, item.data))
			
		vbox.add_child(btn_buy)
		
		shop_items_container.add_child(panel)

func populate_upgrade_station():
	# Clear existing dynamic upgrade panels
	for child in upgrade_items_container.get_children():
		child.queue_free()
		
	if not player:
		return
		
	var inv = player.get_inventory()
	var gold_held = player.get_gold()
	
	for i in range(inv.size()):
		var item = inv[i]
		if not item or item.is_empty():
			continue
			
		var type = item.get("type", "")
		if type != "weapon" and type != "armor" and type != "boots" and type != "crest":
			continue
			
		var grade = item.get("grade", "common")
		if grade != "epic" and grade != "legendary":
			continue
			
		var lvl = item.get("upgrade_level", 0)
		var cost = 50 + lvl * 50
		var is_max = lvl >= 5
		
		# Instantiate upgrade panel card
		var panel = Panel.new()
		panel.custom_minimum_size = Vector2(150, 230)
		
		var margin = MarginContainer.new()
		margin.layout_mode = 1
		margin.anchors_preset = Control.PRESET_FULL_RECT
		margin.add_theme_constant_override("margin_left", 8)
		margin.add_theme_constant_override("margin_right", 8)
		margin.add_theme_constant_override("margin_top", 8)
		margin.add_theme_constant_override("margin_bottom", 8)
		panel.add_child(margin)
		
		var vbox = VBoxContainer.new()
		vbox.layout_mode = 2
		vbox.add_theme_constant_override("separation", 6)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		margin.add_child(vbox)
		
		# Name Label (with level suffix if upgraded)
		var name_lbl = Label.new()
		var suffix = ""
		if lvl > 0:
			suffix = " +%d" % lvl
		name_lbl.text = TranslationManager.t(item.get("name", "")) + suffix
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_lbl.add_theme_font_size_override("font_size", 12)
		
		if grade == "uncommon":
			name_lbl.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))
		elif grade == "rare":
			name_lbl.add_theme_color_override("font_color", Color(0.2, 0.6, 1.0))
		elif grade == "epic":
			name_lbl.add_theme_color_override("font_color", Color(0.8, 0.3, 1.0))
		elif grade == "legendary":
			name_lbl.add_theme_color_override("font_color", Color(1.0, 0.5, 0.0))
		vbox.add_child(name_lbl)
		
		# Description showing current stats
		var desc_lbl = Label.new()
		desc_lbl.custom_minimum_size = Vector2(0, 50)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_lbl.add_theme_font_size_override("font_size", 9)
		desc_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
		
		var stat_desc = ""
		if type == "weapon":
			if TranslationManager.current_locale == "en":
				stat_desc = "ATK: +%d" % int(item.get("atk_bonus", 0.0))
			else:
				stat_desc = "攻击力: +%d" % int(item.get("atk_bonus", 0.0))
		elif type == "armor":
			if TranslationManager.current_locale == "en":
				stat_desc = "DEF: +%d\nHP: +%d" % [int(item.get("def_bonus", 0.0)), int(item.get("hp_bonus", 0.0))]
			else:
				stat_desc = "防御力: +%d\n生命值: +%d" % [int(item.get("def_bonus", 0.0)), int(item.get("hp_bonus", 0.0))]
		elif type == "boots":
			if TranslationManager.current_locale == "en":
				stat_desc = "SPD: +%d" % int(item.get("speed_bonus", 0.0))
			else:
				stat_desc = "移动速度: +%d" % int(item.get("speed_bonus", 0.0))
		elif type == "crest":
			if TranslationManager.current_locale == "en":
				stat_desc = "ATK: +%d\nHP: +%d\nSPD: +%d" % [int(item.get("atk_bonus", 0.0)), int(item.get("hp_bonus", 0.0)), int(item.get("speed_bonus", 0.0))]
			else:
				stat_desc = "攻击: +%d\n生命: +%d\n速度: +%d" % [int(item.get("atk_bonus", 0.0)), int(item.get("hp_bonus", 0.0)), int(item.get("speed_bonus", 0.0))]
		desc_lbl.text = stat_desc
		vbox.add_child(desc_lbl)
		
		# Preview upgrade path
		var preview_lbl = Label.new()
		preview_lbl.custom_minimum_size = Vector2(0, 40)
		preview_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		preview_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		preview_lbl.add_theme_font_size_override("font_size", 9)
		
		if is_max:
			preview_lbl.text = TranslationManager.t("SHOP_MAXED_PREVIEW")
			preview_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.15))
		else:
			# Preview upgraded stats
			preview_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
			var next_lvl = lvl + 1
			var base_atk = item.get("base_atk_bonus", item.get("atk_bonus", 0.0))
			var base_def = item.get("base_def_bonus", item.get("def_bonus", 0.0))
			var base_hp = item.get("base_hp_bonus", item.get("hp_bonus", 0.0))
			var base_speed = item.get("base_speed_bonus", item.get("speed_bonus", 0.0))
			
			var next_atk = base_atk * (1.0 + next_lvl * 0.4)
			var next_def = base_def * (1.0 + next_lvl * 0.4)
			var next_hp = base_hp * (1.0 + next_lvl * 0.4)
			var next_speed = base_speed * (1.0 + next_lvl * 0.4)
			
			if type == "weapon":
				preview_lbl.text = TranslationManager.t("SHOP_NEXT_ATK") % int(next_atk)
			elif type == "armor":
				preview_lbl.text = TranslationManager.t("SHOP_NEXT_ARMOR") % [int(next_def), int(next_hp)]
			elif type == "boots":
				if TranslationManager.current_locale == "en":
					preview_lbl.text = "Next -> SPD: +%d" % int(next_speed)
				else:
					preview_lbl.text = "强化后 -> 速度: +%d" % int(next_speed)
			elif type == "crest":
				if TranslationManager.current_locale == "en":
					preview_lbl.text = "Next -> ATK: +%d\nHP: +%d\nSPD: +%d" % [int(next_atk), int(next_hp), int(next_speed)]
				else:
					preview_lbl.text = "强化后 -> 攻击: +%d\n生命: +%d\n速度: +%d" % [int(next_atk), int(next_hp), int(next_speed)]
		vbox.add_child(preview_lbl)
		
		# Cost Label
		var cost_lbl = Label.new()
		cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost_lbl.add_theme_font_size_override("font_size", 10)
		if is_max:
			cost_lbl.text = TranslationManager.t("SHOP_UPGRADE_COST_MAX")
			cost_lbl.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		else:
			if TranslationManager.current_locale == "en":
				cost_lbl.text = "Cost: %d Gold" % cost
			else:
				cost_lbl.text = "升级需要: %d 金币" % cost
			cost_lbl.add_theme_color_override("font_color", Color(0.9, 0.8, 0.15))
		vbox.add_child(cost_lbl)
		
		# Upgrade Button
		var btn_upgrade = Button.new()
		btn_upgrade.custom_minimum_size = Vector2(0, 26)
		btn_upgrade.add_theme_font_size_override("font_size", 10)
		if is_max:
			btn_upgrade.text = TranslationManager.t("SHOP_UPGRADE_COST_MAX")
			btn_upgrade.disabled = true
		else:
			btn_upgrade.text = TranslationManager.t("SHOP_UPGRADE_BTN")
			if gold_held < cost:
				btn_upgrade.disabled = true
			else:
				btn_upgrade.disabled = false
				btn_upgrade.pressed.connect(func(): _on_upgrade_gear_pressed(i, cost))
		vbox.add_child(btn_upgrade)
		
		upgrade_items_container.add_child(panel)

func _on_upgrade_gear_pressed(slot_index: int, cost: int):
	if not player:
		return
		
	var inv = player.get_inventory()
	if slot_index >= inv.size():
		return
		
	var item = inv[slot_index]
	if not item or item.is_empty():
		return
		
	var current_gold = player.get_gold()
	if current_gold < cost:
		_show_shop_status("金币不足，无法强化！", Color(1, 0.3, 0.1))
		return
		
	var lvl = item.get("upgrade_level", 0)
	if lvl >= 5:
		_show_shop_status("该装备已达到最高强化等级！", Color(1, 0.3, 0.1))
		return
		
	# Deduct gold
	player.set_gold(current_gold - cost)
	
	# Set base stats if not present (using correct bracket notation)
	if not item.has("base_atk_bonus") and item.has("atk_bonus"):
		item["base_atk_bonus"] = item["atk_bonus"]
	if not item.has("base_def_bonus") and item.has("def_bonus"):
		item["base_def_bonus"] = item["def_bonus"]
	if not item.has("base_hp_bonus") and item.has("hp_bonus"):
		item["base_hp_bonus"] = item["hp_bonus"]
	if not item.has("base_speed_bonus") and item.has("speed_bonus"):
		item["base_speed_bonus"] = item["speed_bonus"]
		
	# Back up original description
	if not item.has("original_description"):
		item["original_description"] = item.get("description", "")
		
	var next_lvl = lvl + 1
	item["upgrade_level"] = next_lvl
	
	# Compute new stats (+40% per upgrade level)
	var type = item.get("type", "")
	var multiplier = 1.0 + next_lvl * 0.4
	
	if item.has("base_atk_bonus"):
		item["atk_bonus"] = round(item["base_atk_bonus"] * multiplier)
	if item.has("base_def_bonus"):
		item["def_bonus"] = round(item["base_def_bonus"] * multiplier)
	if item.has("base_hp_bonus"):
		item["hp_bonus"] = round(item["base_hp_bonus"] * multiplier)
	if item.has("base_speed_bonus"):
		item["speed_bonus"] = round(item["base_speed_bonus"] * multiplier)
		
	# Update description with dynamic upgrade suffix
	var upg_suffix = ""
	if TranslationManager.current_locale == "en":
		upg_suffix = "\n⚡ Reinforced: +%d (Stats +%d%%)" % [next_lvl, next_lvl * 40]
	else:
		upg_suffix = "\n⚡ 强化等级: +%d (基础属性提升 +%d%%)" % [next_lvl, next_lvl * 40]
	item["description"] = item.get("original_description", "") + upg_suffix
		
	# Update player inventory
	inv[slot_index] = item
	player.set_inventory(inv)
	
	# Play sound & show success status
	SynthAudio.play_gold(self)
	_show_shop_status("✓ 强化成功：%s -> +%d!" % [TranslationManager.t(item.get("name", "")), next_lvl], Color(0.2, 0.9, 0.2))
	
	# Save game progress
	SaveSystem.save_game(player)
	
	# Update UIs
	_on_gold_changed(player.get_gold())
	_on_inventory_changed()
	populate_upgrade_station()

func open_talent_ui():
	talent_panel.show()
	populate_talents()

func close_talent_ui():
	talent_panel.hide()

func populate_talents():
	for child in talent_rows_container.get_children():
		child.queue_free()
		
	if not player:
		return
		
	var pts = player.get_skill_points()
	talent_points_lbl.text = "可用天赋点数: %d" % pts
	
	var talents_data = [
		{
			"id": "T_CRIT",
			"name": "暴击强化 (Crit Strike)",
			"level": player.get_talent_crit_level(),
			"desc_func": func(lvl): return "增加暴击率。当前: +%d%% -> 下级: +%d%%" % [lvl * 5, (lvl + 1) * 5] if lvl < 4 else "增加暴击率。当前: +20% (已满级)",
			"color": Color(0.9, 0.35, 0.35)
		},
		{
			"id": "T_EVADE",
			"name": "闪避强化 (Evasion)",
			"level": player.get_talent_evasion_level(),
			"desc_func": func(lvl): return "增加避闪率。当前: +%d%% -> 下级: +%d%%" % [lvl * 5, (lvl + 1) * 5] if lvl < 4 else "增加避闪率。当前: +20% (已满级)",
			"color": Color(0.35, 0.9, 0.35)
		},
		{
			"id": "T_LIFE",
			"name": "生命吸取 (Lifesteal)",
			"level": player.get_talent_lifesteal_level(),
			"desc_func": func(lvl): return "击中回复生命值。当前: +%d%% -> 下级: +%d%%" % [lvl * 4, (lvl + 1) * 4] if lvl < 4 else "击中回复生命值。当前: +16% (已满级)",
			"color": Color(0.9, 0.35, 0.9)
		},
		{
			"id": "T_SPEED",
			"name": "急速移速 (Fleet Foot)",
			"level": player.get_talent_speed_level(),
			"desc_func": func(lvl): return "提升移动速度。当前: +%d -> 下级: +%d" % [lvl * 10, (lvl + 1) * 10] if lvl < 4 else "提升移动速度。当前: +40 (已满级)",
			"color": Color(0.35, 0.8, 0.9)
		}
	]
	
	for talent in talents_data:
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 10)
		
		var v_info = VBoxContainer.new()
		v_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(v_info)
		
		# Name & current Level label
		var name_lbl = Label.new()
		name_lbl.text = "%s (Lv %d/4)" % [talent.name, talent.level]
		name_lbl.add_theme_color_override("font_color", talent.color)
		name_lbl.add_theme_font_size_override("font_size", 12)
		v_info.add_child(name_lbl)
		
		# Description label
		var desc_lbl = Label.new()
		desc_lbl.text = talent.desc_func.call(talent.level)
		desc_lbl.add_theme_font_size_override("font_size", 10)
		desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		v_info.add_child(desc_lbl)
		
		# Upgrade "+" Button
		var btn = Button.new()
		btn.text = "+"
		btn.custom_minimum_size = Vector2(30, 30)
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		if talent.level >= 4 or pts <= 0:
			btn.disabled = true
		else:
			btn.disabled = false
			btn.pressed.connect(func(): _on_upgrade_talent_pressed(talent.id))
			
		row.add_child(btn)
		talent_rows_container.add_child(row)

func _on_upgrade_talent_pressed(talent_id: String):
	if player and player.get_skill_points() > 0:
		player.learn_skill(talent_id)
		# Play a learn sound
		SynthAudio.play_gold(self)
		# Save game progress
		SaveSystem.save_game(player)
		# Refresh
		populate_talents()
		_on_skills_changed()

func init_quests():
	var path = get_tree().current_scene.scene_file_path
	active_quests = []
	if path.contains("main.tscn"):
		active_quests.append({"id": "s1_kill_wolves", "name": "消灭森林魔狼", "type": "kill", "target_name": "Wolf", "target_count": 3, "current": 0, "completed": false, "gold_reward": 150, "xp_reward": 200})
		active_quests.append({"id": "s1_buy_potion", "name": "向商人购买1瓶治疗药水", "type": "buy", "target_name": "Potion of Healing", "target_count": 1, "current": 0, "completed": false, "gold_reward": 100, "xp_reward": 100})
	elif path.contains("stage2.tscn"):
		active_quests.append({"id": "s2_kill_spiders", "name": "消灭洞穴地狱蜘蛛", "type": "kill", "target_name": "Spider", "target_count": 5, "current": 0, "completed": false, "gold_reward": 250, "xp_reward": 300})
	elif path.contains("stage3.tscn"):
		active_quests.append({"id": "s3_kill_boss", "name": "击败腐化古树特兰特", "type": "boss", "target_count": 1, "current": 0, "completed": false, "gold_reward": 400, "xp_reward": 500})
	elif path.contains("stage4.tscn"):
		active_quests.append({"id": "s4_kill_spiders", "name": "消灭深渊蛛后护卫", "type": "kill", "target_name": "Wolf/Stalker", "target_count": 6, "current": 0, "completed": false, "gold_reward": 350, "xp_reward": 450})
	elif path.contains("stage5.tscn"):
		active_quests.append({"id": "s5_kill_boss", "name": "击败终极深渊魔主", "type": "boss", "target_count": 1, "current": 0, "completed": false, "gold_reward": 800, "xp_reward": 1000})
	
	update_quest_ui()

func update_quest_ui():
	var list_container = get_node_or_null("Control/QuestPanel/VBox/QuestList")
	if not list_container: return
	
	# Clear old labels
	for child in list_container.get_children():
		child.queue_free()
		
	# Populate new
	for q in active_quests:
		var lbl = Label.new()
		lbl.add_theme_font_size_override("font_size", 10)
		if q.completed:
			lbl.text = " ✓ %s%s" % [TranslationManager.t(q.name), TranslationManager.t("Q_COMPLETED_STATUS")]
			lbl.add_theme_color_override("font_color", Color(0.2, 0.9, 0.2))
		else:
			lbl.text = " • %s (%d/%d)" % [TranslationManager.t(q.name), q.current, q.target_count]
			lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		list_container.add_child(lbl)

func feed_kill(enemy_name: String):
	for q in active_quests:
		if q.completed: continue
		if q.type == "kill":
			if q.target_name.to_lower() in enemy_name.to_lower() or enemy_name.to_lower() in q.target_name.to_lower():
				q.current = min(q.current + 1, q.target_count)
				if q.current >= q.target_count:
					complete_quest(q)
				update_quest_ui()

func feed_boss_kill():
	for q in active_quests:
		if q.completed: continue
		if q.type == "boss":
			q.current = 1
			complete_quest(q)
			update_quest_ui()

func feed_purchase(item_name: String):
	for q in active_quests:
		if q.completed: continue
		if q.type == "buy":
			if q.target_name.to_lower() in item_name.to_lower() or item_name.to_lower() in q.target_name.to_lower():
				q.current = min(q.current + 1, q.target_count)
				if q.current >= q.target_count:
					complete_quest(q)
				update_quest_ui()

func complete_quest(q: Dictionary):
	q.completed = true
	if player:
		player.set_gold(player.get_gold() + q.gold_reward)
		player.add_xp(q.xp_reward)
	SynthAudio.play_gold(self)
	show_achievement_popup(q.name, q.gold_reward, q.xp_reward)

func show_achievement_popup(quest_name: String, gold: int, xp: int):
	var popup = get_node_or_null("Control/AchievementPopup")
	if not popup: return
	
	var label_detail = popup.get_node_or_null("VBox/LabelDetail")
	var label_rewards = popup.get_node_or_null("VBox/LabelRewards")
	
	if label_detail:
		label_detail.text = "【%s】" % TranslationManager.t(quest_name)
	if label_rewards:
		if TranslationManager.current_locale == "en":
			label_rewards.text = "+%d Gold, +%d XP" % [gold, xp]
		else:
			label_rewards.text = "+%d 金币, +%d 经验" % [gold, xp]
		
	popup.show()
	
	popup.position.y = -110.0
	var tween = create_tween()
	tween.tween_property(popup, "position:y", 20.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(3.0)
	tween.tween_property(popup, "position:y", -110.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(popup.hide)

func refresh_translations():
	# Headers & Labels
	var quest_hdr = get_node_or_null("Control/QuestPanel/VBoxContainer/Header")
	if quest_hdr: quest_hdr.text = TranslationManager.t("HUD_STAGE_QUESTS")
	
	var shop_title = get_node_or_null("Control/ShopPanel/VBox/Title")
	if shop_title: shop_title.text = TranslationManager.t("SHOP_TITLE")
	
	var shop_hdr_buy = get_node_or_null("Control/ShopPanel/VBox/HeaderShop")
	if shop_hdr_buy: shop_hdr_buy.text = "—— " + TranslationManager.t("SHOP_BUY") + " ——"
	
	var shop_hdr_upg = get_node_or_null("Control/ShopPanel/VBox/HeaderUpgrade")
	if shop_hdr_upg: shop_hdr_upg.text = "—— " + TranslationManager.t("SHOP_UPGRADE") + " ——"
	
	var shop_close = get_node_or_null("Control/ShopPanel/VBox/BtnClose")
	if shop_close: shop_close.text = "X"
	
	var talent_title = get_node_or_null("Control/TalentPanel/Title")
	if talent_title: talent_title.text = TranslationManager.t("HUD_TALENTS")
	
	btn_open_talents.text = TranslationManager.t("HUD_TALENTS")
	
	# Victory / Defeat Panel Labels
	var victory_title = get_node_or_null("Control/VictoryScreen/VBox/Title")
	if victory_title: victory_title.text = TranslationManager.t("HUD_VICTORY")
	
	var defeat_title = get_node_or_null("Control/GameOverScreen/VBox/Title")
	if defeat_title: defeat_title.text = TranslationManager.t("HUD_DEFEAT")
	
	var btn_restart_game_over = get_node_or_null("Control/GameOverScreen/VBox/BtnRestart")
	if btn_restart_game_over: btn_restart_game_over.text = TranslationManager.t("HUD_REPLAY")
	
	var btn_revive_spot_lbl = get_node_or_null("Control/GameOverScreen/VBox/BtnReviveSpot")
	if btn_revive_spot_lbl: btn_revive_spot_lbl.text = TranslationManager.t("HUD_REVIVE_SPOT")
	
	var btn_revive_base_lbl = get_node_or_null("Control/GameOverScreen/VBox/BtnRevive")
	if btn_revive_base_lbl: btn_revive_base_lbl.text = TranslationManager.t("HUD_REVIVE_BASE")
	
	var btn_menu_game_over = get_node_or_null("Control/GameOverScreen/VBox/BtnMenu")
	if btn_menu_game_over: btn_menu_game_over.text = TranslationManager.t("HUD_RETURN_MENU")
	
	var btn_menu_victory = get_node_or_null("Control/VictoryScreen/VBox/BtnMenu")
	if btn_menu_victory: btn_menu_victory.text = TranslationManager.t("HUD_RETURN_MENU")
	
	var btn_restart_victory = get_node_or_null("Control/VictoryScreen/VBox/BtnRestart")
	if btn_restart_victory: btn_restart_victory.text = TranslationManager.t("HUD_PLAY_AGAIN")
	
	# Refresh dynamic stats
	if player:
		_on_skills_changed()
		_on_gold_changed(player.get_gold())
		update_quest_ui()
		populate_shop()
		populate_upgrade_station()
		populate_talents()
	refresh_notice_texts()

func setup_boss_defeated_notice():
	boss_notice_panel = PanelContainer.new()
	boss_notice_panel.name = "BossDefeatedNotice"
	boss_notice_panel.visible = false
	
	boss_notice_panel.custom_minimum_size = Vector2(400, 200)
	boss_notice_panel.anchors_preset = Control.PRESET_CENTER
	boss_notice_panel.anchor_left = 0.5
	boss_notice_panel.anchor_top = 0.5
	boss_notice_panel.anchor_right = 0.5
	boss_notice_panel.anchor_bottom = 0.5
	boss_notice_panel.grow_horizontal = 2
	boss_notice_panel.grow_vertical = 2
	boss_notice_panel.offset_left = -200
	boss_notice_panel.offset_top = -100
	boss_notice_panel.offset_right = 200
	boss_notice_panel.offset_bottom = 100
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.15, 0.95)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.95, 0.8, 0.15, 1.0)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	boss_notice_panel.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	boss_notice_panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	var title = Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.95, 0.8, 0.15, 1.0))
	vbox.add_child(title)
	
	var desc = Label.new()
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1.0))
	vbox.add_child(desc)
	
	var btn_close = Button.new()
	btn_close.custom_minimum_size = Vector2(160, 36)
	btn_close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_close.pressed.connect(func(): boss_notice_panel.visible = false)
	vbox.add_child(btn_close)
	
	var control_node = get_node_or_null("Control")
	if control_node:
		control_node.add_child(boss_notice_panel)

func show_boss_defeated_notice():
	refresh_notice_texts()
	if boss_notice_panel:
		boss_notice_panel.visible = true

func refresh_notice_texts():
	if boss_notice_panel:
		var vbox = boss_notice_panel.get_child(0).get_child(0)
		var title = vbox.get_child(0)
		var desc = vbox.get_child(1)
		var btn = vbox.get_child(2)
		title.text = "🏆 " + TranslationManager.t("BOSS_DEFEATED_TITLE")
		desc.text = TranslationManager.t("BOSS_DEFEATED_DESC")
		btn.text = "✖ " + TranslationManager.t("BOSS_DEFEATED_BTN")
