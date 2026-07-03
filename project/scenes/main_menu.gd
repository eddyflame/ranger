extends Control

const SaveSystem = preload("res://scenes/save_system.gd")

@onready var btn_continue = $CenterContainer/VBox/BottomRow/BtnContinue

func _ready():
	# Check if save file exists to toggle Continue button
	var save_path = "user://rangers_path_save.json"
	if FileAccess.file_exists(save_path):
		btn_continue.disabled = false
		btn_continue.text = "继续游戏 (继续上次进度)"
	else:
		btn_continue.disabled = true
		btn_continue.text = "暂无存档"

func _on_stage1_pressed():
	# Delete save file when starting a new level so player starts fresh at level 1
	SaveSystem.delete_save()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_stage2_pressed():
	SaveSystem.delete_save()
	get_tree().change_scene_to_file("res://scenes/stage2.tscn")

func _on_stage3_pressed():
	SaveSystem.delete_save()
	get_tree().change_scene_to_file("res://scenes/stage3.tscn")

func _on_continue_pressed():
	var save_path = "user://rangers_path_save.json"
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		var text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		if json.parse(text) == OK:
			var data = json.get_data()
			# Determine which scene to load based on the stored level_index
			var lvl_index = data.get("level_index", 1)
			if lvl_index == 1:
				get_tree().change_scene_to_file("res://scenes/main.tscn")
			elif lvl_index == 2:
				get_tree().change_scene_to_file("res://scenes/stage2.tscn")
			elif lvl_index == 3:
				get_tree().change_scene_to_file("res://scenes/stage3.tscn")
			else:
				get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_quit_pressed():
	get_tree().quit()
