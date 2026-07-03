extends ProgressBar

func _ready():
	var enemy = get_parent()
	if enemy:
		enemy.connect("hp_changed", Callable(self, "_on_hp_changed"))
		max_value = enemy.get_total_max_hp()
		value = enemy.hp
		visible = false

func _on_hp_changed(old_hp, new_hp, max_hp):
	max_value = max_hp
	value = new_hp
	# Show health bar when damaged, hide if full health or dead
	if new_hp < max_hp and new_hp > 0.0:
		visible = true
	else:
		visible = false
