extends CanvasLayer

@onready var hp_bar = $Control/BottomBar/Panel/HPBar
@onready var mp_bar = $Control/BottomBar/Panel/MPBar
@onready var xp_bar = $Control/BottomBar/Panel/XPBar
@onready var hp_lbl = $Control/BottomBar/Panel/HPBar/Label
@onready var mp_lbl = $Control/BottomBar/Panel/MPBar/Label
@onready var stats_lbl = $Control/BottomBar/Panel/StatsLabel
@onready var lvl_lbl = $Control/BottomBar/Panel/LevelLabel

@onready var inv_grid = $Control/BottomBar/Panel/InventoryGrid
@onready var btn_q = $Control/BottomBar/Panel/Skills/BtnQ
@onready var btn_w = $Control/BottomBar/Panel/Skills/BtnW

@onready var game_over_screen = $Control/GameOverScreen
@onready var victory_screen = $Control/VictoryScreen
@onready var instructions = $Control/Instructions

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
		
		# Initial state
		_on_hp_changed(player.hp, player.hp, player.get_total_max_hp())
		_on_mp_changed(player.mp, player.mp, player.get_total_max_mp())
		_on_xp_changed(player.get_xp(), player.get_xp_to_next_level())
		_on_level_up(player.level)
		_on_inventory_changed()
		_on_skills_changed()
		
	# GameManager setup
	var gm = get_tree().root.get_node_or_null("Main/GameManager")
	if gm:
		gm.connect("game_victory", Callable(self, "_on_victory"))
		gm.connect("game_over", Callable(self, "_on_game_over"))

	# Inventory button clicks mapping
	for i in range(6):
		var btn = inv_grid.get_child(i)
		btn.pressed.connect(func(): _on_inventory_slot_pressed(i))

	btn_q.pressed.connect(func(): _on_skill_q_pressed())
	btn_w.pressed.connect(func(): _on_skill_w_pressed())

func _process(delta):
	# Update W skill cooldown visual
	if player:
		var cd = player.get_skill_w_cooldown()
		if cd > 0.0:
			btn_w.text = "W\nCD: %.1f" % cd
			btn_w.disabled = true
		else:
			btn_w.text = "W\nWindwalk"
			btn_w.disabled = false

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

func _on_inventory_changed():
	if not player: return
	var inv = player.get_inventory()
	for i in range(6):
		var btn = inv_grid.get_child(i)
		var item = inv[i]
		if item and not item.is_empty():
			btn.text = item.get("name", "Item")
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

func update_stats_display():
	if not player: return
	var atk = player.get_total_atk()
	var def = player.get_total_def()
	var str_val = player.strength
	var agi_val = player.agility
	var int_val = player.intelligence
	
	stats_lbl.text = "ATK: %d   DEF: %.1f\n力量(STR): %d  敏捷(AGI): %d  智力(INT): %d" % [atk, def, str_val, agi_val, int_val]

func _on_inventory_slot_pressed(slot_index):
	if player:
		player.use_item(slot_index)

func _on_skill_q_pressed():
	if player:
		player.toggle_skill_q()

func _on_skill_w_pressed():
	if player:
		player.cast_skill_w()

func _on_victory():
	victory_screen.show()

func _on_game_over():
	game_over_screen.show()

func _on_restart_pressed():
	var gm = get_tree().root.get_node_or_null("Main/GameManager")
	if gm:
		gm.restart_game()
