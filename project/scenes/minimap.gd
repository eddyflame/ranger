extends Control

var radar_radius: float = 60.0
var map_center: Vector2 = Vector2(70, 70)
var zoom_factor: float = 0.12 # World coordinates to radar offset scale factor

@onready var btn_zoom_in = $BtnZoomIn
@onready var btn_zoom_out = $BtnZoomOut

var player: Node2D = null

func _ready():
	btn_zoom_in.pressed.connect(func():
		zoom_factor = min(zoom_factor + 0.03, 0.3)
		queue_redraw()
	)
	btn_zoom_out.pressed.connect(func():
		zoom_factor = max(zoom_factor - 0.03, 0.04)
		queue_redraw()
	)

func _process(_delta):
	# Center map tracking on player
	if not player or player.is_queued_for_deletion():
		var current_scene = get_tree().current_scene
		if current_scene:
			player = current_scene.get_node_or_null("Player")
	# Force redraw on every frame
	queue_redraw()

func _draw():
	# 1. Draw radar disc background (semi-transparent dark grey/cyan-tint disc)
	draw_circle(map_center, radar_radius, Color(0.06, 0.08, 0.08, 0.72))
	# 2. Draw border ring
	draw_arc(map_center, radar_radius, 0.0, TAU, 64, Color(0.2, 0.85, 0.85, 0.8), 2.0)
	
	if not player or player.is_queued_for_deletion():
		return
		
	var player_pos = player.global_position
	
	# 3. Draw player cyan indicator in center of the radar
	draw_circle(map_center, 4.0, Color(0.2, 0.9, 0.9))
	
	# 4. Iterate through active nodes in current level and plot their positions
	var current_scene = get_tree().current_scene
	if not current_scene:
		return
		
	for child in current_scene.get_children():
		if child == player or child.is_queued_for_deletion() or not child is Node2D:
			continue
			
		var child_pos = child.global_position
		var offset = child_pos - player_pos
		
		# Convert offset to radar coordinates
		var radar_offset = offset * zoom_factor
		
		# Skip drawing if outside radar circle bounds
		if radar_offset.length() > radar_radius:
			continue
			
		var plot_pos = map_center + radar_offset
		
		# Draw appropriate dots based on node characteristics
		if child.is_in_group("enemies") and not child.call("get_is_dead"):
			var is_boss = ("Boss" in child.name) or child.is_in_group("bosses") or child.has_method("get_current_phase")
			if is_boss:
				# Pulsing orange dot for final Bosses
				var pulse = (sin(Time.get_ticks_msec() * 0.01) + 1.0) * 0.5
				var boss_color = Color(1.0, 0.4 + pulse * 0.3, 0.1)
				draw_circle(plot_pos, 5.5, boss_color)
			else:
				# Red dot for regular wolves/spitters/spiderlings
				draw_circle(plot_pos, 3.2, Color(0.9, 0.2, 0.2))
		elif "Merchant" in child.name:
			# Green dot for merchant
			draw_circle(plot_pos, 4.0, Color(0.2, 0.9, 0.2))
		elif "ExitPortal" in child.name or "Portal" in child.name:
			# Gold star/dot for ending exit portals
			draw_circle(plot_pos, 5.0, Color(0.95, 0.85, 0.15))
			
	# Draw crosshair grids in center of the radar disc for HUD decoration
	draw_line(map_center - Vector2(8, 0), map_center + Vector2(8, 0), Color(0.2, 0.85, 0.85, 0.25), 1.0)
	draw_line(map_center - Vector2(0, 8), map_center + Vector2(0, 8), Color(0.2, 0.85, 0.85, 0.25), 1.0)
