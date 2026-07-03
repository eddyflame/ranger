extends StaticBody2D

func _ready():
	add_to_group("merchants")

func open_shop(player):
	var hud = get_tree().current_scene.get_node_or_null("HUD")
	if hud:
		hud.call("open_shop_ui", player)
