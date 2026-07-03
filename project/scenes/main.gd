extends Node2D

@onready var claw_item = $ItemDrop_Claws
@onready var boots_item = $ItemDrop_Boots
@onready var potion_item = $ItemDrop_Potion
@onready var wolf1 = $Enemy_Wolf1
@onready var wolf2 = $Enemy_Wolf2
@onready var wolf3 = $Enemy_Wolf3
@onready var player = $Player

# Static road outlines to prevent get_outline count out of bounds crashes
var OUTLINE_POINTS := PackedVector2Array([
	Vector2(0, 150), Vector2(400, 150), Vector2(400, 250), Vector2(600, 250),
	Vector2(600, 100), Vector2(1000, 100), Vector2(1000, 250), Vector2(1200, 250),
	Vector2(1200, 150), Vector2(1600, 150), Vector2(1600, 450), Vector2(1200, 450),
	Vector2(1200, 350), Vector2(1000, 350), Vector2(1000, 500), Vector2(600, 500),
	Vector2(600, 350), Vector2(400, 350), Vector2(400, 450), Vector2(0, 450)
])

func _ready():
	print("--- MAIN READY: PRINTING CHILDREN ---")
	for child in get_children():
		print("Child Name: ", child.name, " | Class: ", child.get_class(), " | Position: ", child.position if child is Node2D else "N/A")
	print("-------------------------------------")
	
	# 1. Draw ground road visuals matching path
	create_road_visual()
	
	# 2. Spawn forest border walls
	spawn_forest_borders()

	# Define item datas
	var claws_data = {
		"name": "Claws of Attack +6",
		"type": "weapon",
		"atk_bonus": 6.0,
		"description": "Increases Attack Power by 6."
	}
	var boots_data = {
		"name": "Boots of Speed",
		"type": "boots",
		"speed_bonus": 45.0,
		"description": "Increases Movement Speed by 45."
	}
	var potion_data = {
		"name": "Potion of Healing",
		"type": "potion",
		"hp_restore": 150.0,
		"description": "Consumable. Restores 150 HP."
	}
	
	if claw_item:
		claw_item.set_item_data(claws_data)
	if boots_item:
		boots_item.set_item_data(boots_data)
	if potion_item:
		potion_item.set_item_data(potion_data)
		
	# Configure wolf loot tables (chance to drop on death)
	if wolf1:
		wolf1.add_loot_item(potion_data)
	if wolf2:
		wolf2.add_loot_item(claws_data)
	if wolf3:
		wolf3.add_loot_item(potion_data)
		
	# 4. Connect signals for all Character children (for damage / healing floating numbers)
	for child in get_children():
		if child.has_signal("damage_taken"):
			child.connect("damage_taken", Callable(self, "_on_character_damage_taken").bind(child))
		if child.has_signal("healed"):
			child.connect("healed", Callable(self, "_on_character_healed").bind(child))
		if child.has_signal("boss_stomped"):
			child.connect("boss_stomped", Callable(self, "_on_boss_stomped").bind(child))
			
	# Connect XP gained on player
	if player and player.has_signal("xp_gained"):
		player.connect("xp_gained", Callable(self, "_on_player_xp_gained"))
	


func create_road_visual():
	var road = Polygon2D.new()
	road.polygon = OUTLINE_POINTS
	road.color = Color(0.18, 0.16, 0.13, 1.0) # Sleek modern dark road gravel
	road.z_index = -8
	add_child(road)
	
	# Add a border line to the road for aesthetic polish
	var road_border = Line2D.new()
	road_border.points = OUTLINE_POINTS
	# Close the line path loop
	road_border.add_point(OUTLINE_POINTS[0])
	road_border.width = 3.0
	road_border.default_color = Color(0.24, 0.22, 0.18, 1.0)
	road_border.z_index = -7
	add_child(road_border)

func spawn_forest_borders():
	var tree_scene = preload("res://scenes/tree.tscn")
	var outlines = OUTLINE_POINTS
	
	for i in range(outlines.size()):
		var p1 = outlines[i]
		var p2 = outlines[(i + 1) % outlines.size()]
		
		var segment_dir = p2 - p1
		var segment_length = segment_dir.length()
		var step_dist = 36.0 # Distance between tree nodes
		var steps = int(segment_length / step_dist)
		
		var dir_norm = segment_dir.normalized()
		var outward_normal = Vector2(dir_norm.y, -dir_norm.x)
		
		for j in range(steps):
			var spawn_pos = p1 + dir_norm * (j * step_dist)
			# Push the tree outwards to clear the road/navigation area from colliders
			spawn_pos += outward_normal * 18.0
			# Random offset for a natural organic layout
			spawn_pos += Vector2(randf_range(-6, 6), randf_range(-6, 6))
			
			var tree_inst = tree_scene.instantiate()
			tree_inst.global_position = spawn_pos
			# Add random visual sizes
			var scale_factor = randf_range(0.85, 1.2)
			tree_inst.get_node("Visual").scale = Vector2(scale_factor, scale_factor)
			add_child(tree_inst)

func _on_character_damage_taken(amount: float, attacker: Node, victim: Node):
	if amount <= 0.0: return
	
	var color = Color(0.95, 0.2, 0.2) # Default red for physical damage
	
	# Check if attacker is projectile and had searing effect active
	if attacker and attacker.has_method("get_searing_effect") and attacker.call("get_searing_effect"):
		color = Color(1.0, 0.5, 0.0) # Searing Orange for Searing Arrows
	
	# If the victim is the Player, make it a darker red, if enemy make it bright red/orange
	if victim == player:
		color = Color(1.0, 0.1, 0.1)
		
	spawn_floating_text(victim.global_position + Vector2(0, -20), "-%d" % int(amount), color)

func _on_character_healed(amount: float, victim: Node):
	if amount <= 0.0: return
	spawn_floating_text(victim.global_position + Vector2(0, -20), "+%d HP" % int(amount), Color(0.2, 0.9, 0.2))

func _on_player_xp_gained(amount: int):
	if amount <= 0: return
	spawn_floating_text(player.global_position + Vector2(0, -40), "+%d XP" % amount, Color(0.7, 0.3, 0.9))

func spawn_floating_text(pos: Vector2, text: String, color: Color):
	var label = Label.new()
	label.text = text
	label.label_settings = LabelSettings.new()
	label.label_settings.font_size = 14
	label.label_settings.font_color = color
	label.label_settings.outline_size = 3
	label.label_settings.outline_color = Color.BLACK
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.z_index = 100
	
	# Small random offset so texts don't stack perfectly
	label.global_position = pos + Vector2(randf_range(-15, 15), randf_range(-10, 10))
	add_child(label)
	
	var tween = create_tween()
	# Float upwards and fade out
	tween.tween_property(label, "global_position", label.global_position + Vector2(0, -50), 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.7)
	tween.tween_callback(label.queue_free)

func _on_boss_stomped(pos: Vector2, radius: float, boss_node: Node):
	# Create a visual shockwave expanding ring
	var stomp_ring = Line2D.new()
	var points = PackedVector2Array()
	var segments = 32
	for i in range(segments + 1):
		var angle = (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)))
	stomp_ring.points = points
	stomp_ring.width = 4.0
	stomp_ring.default_color = Color(1.0, 0.45, 0.2, 0.8) # bright warning orange
	stomp_ring.global_position = pos
	stomp_ring.scale = Vector2(5.0, 5.0) # Start small
	stomp_ring.z_index = -3
	add_child(stomp_ring)
	
	spawn_floating_text(pos + Vector2(0, -70), "WAR STOMP!", Color(1.0, 0.25, 0.1))
	
	var tween = create_tween()
	# Expand to stomp radius and fade out
	tween.tween_property(stomp_ring, "scale", Vector2(radius, radius), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(stomp_ring, "modulate:a", 0.0, 0.5)
	tween.tween_callback(stomp_ring.queue_free)
