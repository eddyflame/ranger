extends Node2D

const SynthAudio = preload("res://scenes/synth_audio.gd")
const SaveSystem = preload("res://scenes/save_system.gd")

@onready var player = $Player

# Enemy respawn data
var enemy_spawn_data: Array = []
var respawn_timer: Timer = null

# Winding cursed sanctum path outline — wide spiraling maze with dead-end pockets
var OUTLINE_POINTS := PackedVector2Array([
	Vector2(0, 150), Vector2(450, 150), Vector2(450, 50), Vector2(900, 50),
	Vector2(900, 200), Vector2(1150, 200), Vector2(1150, 80), Vector2(1600, 80),
	Vector2(1600, 550), Vector2(1150, 550), Vector2(1150, 420), Vector2(900, 420),
	Vector2(900, 580), Vector2(450, 580), Vector2(450, 430), Vector2(0, 430)
])

func _ready():
	SynthAudioManager.set_bgm_mode("explore")

	# Dynamic Map Inflation — wider arena for end-game kiting
	var map_scale := 2.2
	var centroid := Vector2.ZERO
	for p in OUTLINE_POINTS:
		centroid += p
	centroid /= OUTLINE_POINTS.size()

	for i in range(OUTLINE_POINTS.size()):
		var dir = OUTLINE_POINTS[i] - centroid
		OUTLINE_POINTS[i] = centroid + dir * map_scale

	# Scale starting positions of player and existing enemies
	for child in get_children():
		if child.is_in_group("enemies") or child == player:
			var dir = child.global_position - centroid
			child.global_position = centroid + dir * map_scale

	# Update Camera2D limits dynamically to match the inflated map
	if player:
		var camera = player.get_node_or_null("Camera2D")
		if camera:
			var min_x = OUTLINE_POINTS[0].x
			var max_x = OUTLINE_POINTS[0].x
			var min_y = OUTLINE_POINTS[0].y
			var max_y = OUTLINE_POINTS[0].y
			for p in OUTLINE_POINTS:
				min_x = min(min_x, p.x)
				max_x = max(max_x, p.x)
				min_y = min(min_y, p.y)
				max_y = max(max_y, p.y)
			camera.limit_left = int(min_x - 300)
			camera.limit_right = int(max_x + 300)
			camera.limit_top = int(min_y - 200)
			camera.limit_bottom = int(max_y + 200)

	# Programmatically duplicate normal enemies to increase density
	var existing_mobs = []
	for child in get_children():
		if child.is_in_group("enemies"):
			existing_mobs.append(child)

	for mob in existing_mobs:
		var mob_name = mob.name.to_lower()
		if "boss" in mob_name or "lich" in mob_name or "queen" in mob_name or "mage" in mob_name:
			continue
		var path = mob.scene_file_path
		if path != "":
			var scene = load(path)
			if scene:
				var extra = scene.instantiate()
				var angle = randf() * TAU
				var dist = randf_range(120.0, 240.0)
				extra.global_position = mob.global_position + Vector2(cos(angle), sin(angle)) * dist
				add_child(extra)

	# Build Navigation Polygon dynamically covering the map's bounding box
	var nav_region = $NavigationRegion2D
	if nav_region:
		var min_x = OUTLINE_POINTS[0].x
		var max_x = OUTLINE_POINTS[0].x
		var min_y = OUTLINE_POINTS[0].y
		var max_y = OUTLINE_POINTS[0].y
		for p in OUTLINE_POINTS:
			min_x = min(min_x, p.x)
			max_x = max(max_x, p.x)
			min_y = min(min_y, p.y)
			max_y = max(max_y, p.y)

		var bounding_box = PackedVector2Array([
			Vector2(min_x - 600, min_y - 400),
			Vector2(max_x + 600, min_y - 400),
			Vector2(max_x + 600, max_y + 400),
			Vector2(min_x - 600, max_y + 400)
		])
		var nav_poly = NavigationPolygon.new()
		nav_poly.add_outline(bounding_box)
		nav_poly.make_polygons_from_outlines()
		nav_region.navigation_polygon = nav_poly

	if player:
		if not SaveSystem.load_game(player):
			# Baseline stats for starting Stage 6 directly (Level 15, full gear)
			player.set_level(15)
			player.set_skill_points(14)
			player.set_gold(2500)
			var starter_inv = [
				{"name": "Cursed Blade", "type": "weapon", "atk_bonus": 14.0, "crit_chance": 0.08, "description": "+14 ATK, +8% Crit."},
				{"name": "Abyssal Plate", "type": "armor", "def_bonus": 4.0, "hp_bonus": 80.0, "description": "+4 DEF, +80 HP."},
				{"name": "Potion of Healing", "type": "potion", "hp_restore": 200.0, "description": "Consumable. Restores 200 HP."},
				{}, {}, {}, {}, {}
			]
			player.set_inventory(starter_inv)
			player.set_hp(player.get_total_max_hp())
			player.set_mp(player.get_total_max_mp())

	# Draw ground road visuals (cursed dark stone)
	create_road_visual()

	# Spawn bone-pillar borders
	spawn_bone_pillar_borders()
	spawn_boundary_walls()

	# Spawn eerie ambient ghost-fire particles along the path
	spawn_ghost_fire_ambient()

	# Record enemy spawn info for 1-minute respawn
	for child in get_children():
		if child.is_in_group("enemies"):
			var path = child.scene_file_path
			if path == "":
				var cname = child.name.to_lower()
				if "abyssboss" in cname or "abyss" in cname or "lich" in cname:
					path = "res://scenes/abyss_boss.tscn"
				elif "spiderqueen" in cname or "queen" in cname:
					path = "res://scenes/spider_queen.tscn"
				elif "boss" in cname:
					path = "res://scenes/boss.tscn"
				elif "ranged" in cname or "spitter" in cname:
					path = "res://scenes/ranged_enemy.tscn"
				elif "spiderling" in cname:
					path = "res://scenes/spiderling.tscn"
				else:
					path = "res://scenes/enemy.tscn"
			var is_b = "boss" in child.name.to_lower() or "lich" in child.name.to_lower() or "queen" in child.name.to_lower()
			enemy_spawn_data.append({
				"scene_path": path,
				"position": child.global_position,
				"is_boss": is_b
			})

	# Setup 1-minute respawn timer
	respawn_timer = Timer.new()
	respawn_timer.wait_time = 60.0
	respawn_timer.one_shot = false
	respawn_timer.autostart = true
	respawn_timer.timeout.connect(_respawn_enemies)
	add_child(respawn_timer)

	# Connect signals for all Character children
	for child in get_children():
		if child.has_signal("damage_taken"):
			child.connect("damage_taken", Callable(self, "_on_character_damage_taken").bind(child))
		if child.has_signal("healed"):
			child.connect("healed", Callable(self, "_on_character_healed").bind(child))
		if child.has_signal("boss_stomped"):
			child.connect("boss_stomped", Callable(self, "_on_boss_stomped").bind(child))
		if child.has_signal("slow_applied"):
			child.connect("slow_applied", Callable(self, "_on_character_slow_applied").bind(child))
		if child.is_in_group("enemies") and child.has_signal("died"):
			child.connect("died", Callable(self, "_on_enemy_died").bind(child))

	# Connect AbyssBoss (Shadow Lich uses AbyssBoss class) phase transition signal
	var boss = get_node_or_null("Boss")
	if boss and boss.has_signal("phase_transition_started"):
		boss.connect("phase_transition_started", Callable(self, "_on_boss_phase_transition"))

	# Connect player signals
	if player:
		if player.has_signal("xp_gained"):
			player.connect("xp_gained", Callable(self, "_on_player_xp_gained"))
		if player.has_signal("gold_gained"):
			player.connect("gold_gained", Callable(self, "_on_player_gold_gained"))
		if player.has_signal("shot_projectile"):
			player.connect("shot_projectile", func():
				if player.get_skill_q_active() and player.mp >= 8.0:
					SynthAudio.play_searing_arrow(self)
				else:
					SynthAudio.play_shoot(self)
			)
		if player.has_signal("blinked"):
			player.connect("blinked", Callable(self, "_on_player_blinked"))
		if player.has_signal("level_up"):
			player.connect("level_up", Callable(self, "_on_player_level_up"))
		if player.has_signal("died"):
			player.connect("died", func():
				var delay_timer = get_tree().create_timer(3.0)
				delay_timer.timeout.connect(func():
					var gm = get_node_or_null("GameManager")
					if gm: gm.trigger_game_over()
				)
			)


func create_road_visual():
	# Dark cursed sanctum stone — nearly black with a faint violet shimmer
	var road = Polygon2D.new()
	road.polygon = OUTLINE_POINTS
	road.color = Color(0.08, 0.06, 0.12, 1.0)
	road.z_index = -8
	add_child(road)

	var road_border = Line2D.new()
	road_border.points = OUTLINE_POINTS
	road_border.add_point(OUTLINE_POINTS[0])
	road_border.width = 3.5
	road_border.default_color = Color(0.45, 0.15, 0.75, 0.9) # Arcane violet glow edge
	road_border.z_index = -7
	add_child(road_border)


func spawn_bone_pillar_borders():
	var tree_scene = preload("res://scenes/tree.tscn")
	var outlines = OUTLINE_POINTS

	for i in range(outlines.size()):
		var p1 = outlines[i]
		var p2 = outlines[(i + 1) % outlines.size()]

		var segment_dir = p2 - p1
		var segment_length = segment_dir.length()
		var step = 95.0
		var current_dist = 0.0

		while current_dist < segment_length:
			var ratio = current_dist / segment_length
			var spawn_pos = p1 + segment_dir * ratio

			var pillar = tree_scene.instantiate()
			pillar.global_position = spawn_pos
			# Bone-white skeletal pillar tint
			pillar.modulate = Color(0.82, 0.80, 0.88, 1.0)
			pillar.scale = Vector2(0.85, 1.35)
			add_child(pillar)

			current_dist += step


func spawn_ghost_fire_ambient():
	# Scatter small CPUParticles2D flame emitters along the path border as ambiance
	var outline = OUTLINE_POINTS
	var num_fires = 18
	for i in range(num_fires):
		var idx = int(randf_range(0, outline.size()))
		var base_pos = outline[idx]
		var offset = Vector2(randf_range(-60, 60), randf_range(-50, 50))

		var particles = CPUParticles2D.new()
		particles.emitting = true
		particles.amount = 6
		particles.lifetime = 1.8
		particles.speed_scale = 1.2
		particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		particles.emission_sphere_radius = 5.0
		particles.gravity = Vector2(0, -25)
		particles.scale_amount_min = 1.5
		particles.scale_amount_max = 3.5
		particles.color = Color(0.35, 0.05, 0.85, 0.75) # Deep ghostly violet
		particles.global_position = base_pos + offset
		particles.z_index = -6
		add_child(particles)


func _respawn_enemies():
	var living = get_tree().get_nodes_in_group("enemies")
	if living.size() >= 30:
		return
	print("[Stage 6] Respawning enemies...")
	for data in enemy_spawn_data:
		if data.get("is_boss", false):
			continue
		var enemy_scene = load(data.scene_path)
		if enemy_scene:
			var enemy = enemy_scene.instantiate()
			enemy.global_position = data.position
			add_child(enemy)

			if enemy.has_signal("damage_taken"):
				enemy.connect("damage_taken", Callable(self, "_on_character_damage_taken").bind(enemy))
			if enemy.has_signal("died"):
				enemy.connect("died", Callable(self, "_on_enemy_died").bind(enemy))
			if enemy.has_signal("slow_applied"):
				enemy.connect("slow_applied", Callable(self, "_on_character_slow_applied").bind(enemy))

			spawn_floating_text(enemy.global_position + Vector2(0, -30), "💀 亡灵复生！", Color(0.65, 0.25, 0.9))


func _on_boss_phase_transition():
	var boss = get_node_or_null("Boss")
	if not boss: return

	spawn_floating_text(boss.global_position + Vector2(0, -100), "💀【亡灵巫王第二形态！】💀", Color(0.85, 0.15, 1.0))
	spawn_floating_text(boss.global_position + Vector2(0, -68), "⚠️ 【不死之躯 — 无法被减速！】", Color(0.7, 0.4, 1.0))

	if player:
		player.trigger_shake(18.0, 1.2)

	SynthAudio.play_stomp(self)
	SynthAudio.play_hit(self)


func _on_enemy_died(enemy_node):
	if not enemy_node: return
	var is_boss = ("Boss" in enemy_node.name or "Lich" in enemy_node.name)
	var death_pos = enemy_node.global_position

	var hud = get_node_or_null("HUD")
	if hud:
		if is_boss:
			hud.feed_boss_kill()
			hud.show_boss_defeated_notice()
		else:
			hud.feed_kill(enemy_node.character_name)

	if is_boss:
		# 5 legendary drops — final boss reward
		for i in range(5):
			var loot = SaveSystem.generate_graded_loot(true)
			var scatter = Vector2(randf_range(-80, 80), randf_range(-60, 60))
			SaveSystem.spawn_loot_drop(self, death_pos + scatter, loot)
			SaveSystem.register_unlocked_item(loot)

		# Find far-right outline point for portal
		var max_pt = OUTLINE_POINTS[0]
		for p in OUTLINE_POINTS:
			if p.x > max_pt.x:
				max_pt = p

		# Spawn exit portal
		var portal_scene = load("res://scenes/exit_portal.tscn")
		if portal_scene:
			var portal = portal_scene.instantiate()
			portal.global_position = max_pt
			add_child(portal)
			print("[Boss Defeat] Stage 6 exit portal spawned at: ", max_pt)

		spawn_floating_text(death_pos + Vector2(0, -90), "🏆 亡灵巫王已灭！游侠之路全通关！", Color(1.0, 0.85, 0.15))
		spawn_floating_text(death_pos + Vector2(0, -55), "★ 传说结局解锁！ ★", Color(0.85, 0.4, 1.0))
	else:
		# 30% chance to drop gear for regular enemies (slightly higher than earlier stages)
		if randf() <= 0.30:
			var loot = SaveSystem.generate_graded_loot(false)
			SaveSystem.spawn_loot_drop(self, death_pos, loot)
			SaveSystem.register_unlocked_item(loot)

	if player:
		SaveSystem.save_game(player)


func _on_character_slow_applied(duration: float, victim: Node):
	spawn_floating_text(victim.global_position + Vector2(0, -35), "减速 (Slowed)!", Color(0.65, 0.25, 0.85))


func _on_character_damage_taken(amount: float, attacker: Node, victim: Node):
	if amount <= 0.0:
		spawn_floating_text(victim.global_position + Vector2(randf_range(-20, 20), -45), "闪避 (Evaded)!", Color(0.3, 0.9, 0.3))
	else:
		SaveSystem.spawn_hit_sparks(self, victim.global_position)
		var color = Color(0.85, 0.15, 0.15) if victim == player else Color(1.0, 1.0, 1.0)
		var text_prefix = ""
		if attacker and attacker.has_meta("last_hit_was_crit") and attacker.get_meta("last_hit_was_crit"):
			attacker.remove_meta("last_hit_was_crit")
			color = Color(1.0, 0.15, 0.15)
			text_prefix = TranslationManager.t("ALERT_CRIT")
			if victim == player:
				player.call("trigger_shake", 12.0, 0.3)
			else:
				if player: player.call("trigger_shake", 8.0, 0.2)

		spawn_floating_text(victim.global_position + Vector2(randf_range(-15, 15), -45), "%s-%d" % [text_prefix, int(amount)], color)
		if text_prefix == TranslationManager.t("ALERT_CRIT"):
			SynthAudio.play_crit(self)
		else:
			SynthAudio.play_hit(self)


func _on_character_healed(amount: float, victim: Node):
	spawn_floating_text(victim.global_position + Vector2(0, -45), "+%d HP" % int(amount), Color(0.2, 0.9, 0.2))


func _on_boss_stomped(victim: Node):
	spawn_floating_text(victim.global_position + Vector2(0, -35), "💀 死灵震击 (Death Stomp)!", Color(0.7, 0.2, 1.0))


func _on_player_xp_gained(amount: int):
	if player:
		spawn_floating_text(player.global_position + Vector2(0, -55), "+%d XP" % amount, Color(0.85, 0.85, 0.15))


func _on_player_gold_gained(amount: int):
	if player:
		spawn_floating_text(player.global_position + Vector2(0, -70), "+%d Gold" % amount, Color(0.95, 0.8, 0.15))


func _on_player_blinked(from_pos: Vector2, to_pos: Vector2):
	var blink_p_scene = load("res://scenes/blink_particles.tscn")
	if blink_p_scene:
		var bp1 = blink_p_scene.instantiate()
		bp1.global_position = from_pos
		add_child(bp1)
		var bp2 = blink_p_scene.instantiate()
		bp2.global_position = to_pos
		add_child(bp2)
	SynthAudio.play_shoot(self)


func _on_player_level_up(new_level: int):
	if player:
		spawn_floating_text(player.global_position + Vector2(0, -85), "✨ LEVEL UP!! ✨", Color(0.6, 0.2, 1.0))
		var lvl_up_p = load("res://scenes/level_up_particles.tscn")
		if lvl_up_p:
			var particles = lvl_up_p.instantiate()
			player.add_child(particles)
		SynthAudio.play_level_up(self)


func spawn_floating_text(pos: Vector2, text: String, color: Color):
	var lbl = Label.new()
	lbl.text = text
	lbl.global_position = pos
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", 11)
	add_child(lbl)

	var tween = create_tween()
	tween.tween_property(lbl, "global_position", pos + Vector2(0, -45), 1.2)
	tween.parallel().tween_property(lbl, "modulate:a", 0.0, 1.2)
	tween.tween_callback(lbl.queue_free)


func spawn_boundary_walls():
	var min_x = OUTLINE_POINTS[0].x
	var max_x = OUTLINE_POINTS[0].x
	var min_y = OUTLINE_POINTS[0].y
	var max_y = OUTLINE_POINTS[0].y
	for p in OUTLINE_POINTS:
		min_x = min(min_x, p.x)
		max_x = max(max_x, p.x)
		min_y = min(min_y, p.y)
		max_y = max(max_y, p.y)

	var left = min_x - 300
	var right = max_x + 300
	var top = min_y - 200
	var bottom = max_y + 200

	var walls = [
		{ "pos": Vector2(left - 10, (top + bottom)/2.0), "size": Vector2(20, (bottom - top) + 100) },
		{ "pos": Vector2(right + 10, (top + bottom)/2.0), "size": Vector2(20, (bottom - top) + 100) },
		{ "pos": Vector2((left + right)/2.0, top - 10), "size": Vector2((right - left) + 100, 20) },
		{ "pos": Vector2((left + right)/2.0, bottom + 10), "size": Vector2((right - left) + 100, 20) }
	]

	for w in walls:
		var sb = StaticBody2D.new()
		sb.collision_layer = 1
		sb.collision_mask = 0

		var col = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = w.size
		col.shape = shape
		sb.add_child(col)

		sb.global_position = w.pos
		add_child(sb)
