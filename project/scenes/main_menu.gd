extends Control

const SaveSystem = preload("res://scenes/save_system.gd")

@onready var btn_continue = $CenterContainer/VBox/BottomRow/BtnContinue
@onready var card_stage1 = $CenterContainer/VBox/LevelSelectRow/CardStage1
@onready var btn_start1 = $CenterContainer/VBox/LevelSelectRow/CardStage1/VBox/BtnStart1
@onready var lbl_header1 = $CenterContainer/VBox/LevelSelectRow/CardStage1/VBox/Header
@onready var lbl_name1 = $CenterContainer/VBox/LevelSelectRow/CardStage1/VBox/Name

@onready var card_stage2 = $CenterContainer/VBox/LevelSelectRow/CardStage2
@onready var btn_start2 = $CenterContainer/VBox/LevelSelectRow/CardStage2/VBox/BtnStart2
@onready var lbl_header2 = $CenterContainer/VBox/LevelSelectRow/CardStage2/VBox/Header
@onready var lbl_name2 = $CenterContainer/VBox/LevelSelectRow/CardStage2/VBox/Name

@onready var card_stage3 = $CenterContainer/VBox/LevelSelectRow/CardStage3
@onready var btn_start3 = $CenterContainer/VBox/LevelSelectRow/CardStage3/VBox/BtnStart3
@onready var lbl_header3 = $CenterContainer/VBox/LevelSelectRow/CardStage3/VBox/Header
@onready var lbl_name3 = $CenterContainer/VBox/LevelSelectRow/CardStage3/VBox/Name

@onready var card_stage4 = $CenterContainer/VBox/LevelSelectRow/CardStage4
@onready var btn_start4 = $CenterContainer/VBox/LevelSelectRow/CardStage4/VBox/BtnStart4
@onready var lbl_header4 = $CenterContainer/VBox/LevelSelectRow/CardStage4/VBox/Header
@onready var lbl_name4 = $CenterContainer/VBox/LevelSelectRow/CardStage4/VBox/Name

@onready var card_stage5 = $CenterContainer/VBox/LevelSelectRow/CardStage5
@onready var btn_start5 = $CenterContainer/VBox/LevelSelectRow/CardStage5/VBox/BtnStart5
@onready var lbl_header5 = $CenterContainer/VBox/LevelSelectRow/CardStage5/VBox/Header
@onready var lbl_name5 = $CenterContainer/VBox/LevelSelectRow/CardStage5/VBox/Name

func _ready():
	SynthAudioManager.set_bgm_mode("menu")
	var max_unlocked = 1
	var save_path = "user://rangers_path_save.json"
	if FileAccess.file_exists(save_path):
		btn_continue.disabled = false
		btn_continue.text = "继续上次游戏"
		
		# Read max_unlocked_level from save
		var file = FileAccess.open(save_path, FileAccess.READ)
		if file:
			var text = file.get_as_text()
			file.close()
			var json = JSON.new()
			if json.parse(text) == OK:
				var data = json.get_data()
				if typeof(data) == TYPE_DICTIONARY:
					max_unlocked = int(data.get("max_unlocked_level", 1))
	else:
		btn_continue.disabled = true
		btn_continue.text = "暂无存档"

	# Style Stage 1 Card (Always Unlocked)
	btn_start1.disabled = false
	btn_start1.text = "进入关卡"
	card_stage1.modulate = Color(1.0, 1.0, 1.0, 1.0)
	if max_unlocked >= 2:
		# Stage 1 is cleared
		lbl_header1.text = "第一关 (已通关)"
		lbl_header1.add_theme_color_override("font_color", Color(0.95, 0.8, 0.2))
		lbl_name1.add_theme_color_override("font_color", Color(0.95, 0.8, 0.2))
	else:
		lbl_header1.text = "第一关"
		lbl_header1.add_theme_color_override("font_color", Color(0.4, 0.7, 0.4)) # Base green

	# Style Stage 2 Card
	if max_unlocked >= 2:
		btn_start2.disabled = false
		btn_start2.text = "进入关卡"
		card_stage2.modulate = Color(1.0, 1.0, 1.0, 1.0)
		if max_unlocked >= 3:
			# Stage 2 is cleared
			lbl_header2.text = "第二关 (已通关)"
			lbl_header2.add_theme_color_override("font_color", Color(0.95, 0.8, 0.2))
			lbl_name2.add_theme_color_override("font_color", Color(0.95, 0.8, 0.2))
		else:
			lbl_header2.text = "第二关"
			lbl_header2.add_theme_color_override("font_color", Color(0.4, 0.7, 0.8)) # Base blue/cyan
	else:
		btn_start2.disabled = true
		btn_start2.text = "未解锁"
		lbl_header2.text = "第二关"
		card_stage2.modulate = Color(0.4, 0.4, 0.4, 0.8)

	# Style Stage 3 Card
	if max_unlocked >= 3:
		btn_start3.disabled = false
		btn_start3.text = "进入关卡"
		card_stage3.modulate = Color(1.0, 1.0, 1.0, 1.0)
		if max_unlocked >= 4:
			# Stage 3 is cleared
			lbl_header3.text = "第三关 (已通关)"
			lbl_header3.add_theme_color_override("font_color", Color(0.95, 0.8, 0.2))
			lbl_name3.add_theme_color_override("font_color", Color(0.95, 0.8, 0.2))
		else:
			lbl_header3.text = "第三关"
			lbl_header3.add_theme_color_override("font_color", Color(0.85, 0.45, 1.0)) # Base purple
	else:
		btn_start3.disabled = true
		btn_start3.text = "未解锁"
		lbl_header3.text = "第三关"
		card_stage3.modulate = Color(0.4, 0.4, 0.4, 0.8)

	# Style Stage 4 Card
	if max_unlocked >= 4:
		btn_start4.disabled = false
		btn_start4.text = "进入关卡"
		card_stage4.modulate = Color(1.0, 1.0, 1.0, 1.0)
		if max_unlocked >= 5:
			# Stage 4 is cleared
			lbl_header4.text = "第四关 (已通关)"
			lbl_header4.add_theme_color_override("font_color", Color(0.95, 0.8, 0.2))
			lbl_name4.add_theme_color_override("font_color", Color(0.95, 0.8, 0.2))
		else:
			lbl_header4.text = "第四关"
			lbl_header4.add_theme_color_override("font_color", Color(1.0, 0.6, 0.1)) # Base orange/gold
	else:
		btn_start4.disabled = true
		btn_start4.text = "未解锁"
		lbl_header4.text = "第四关"
		card_stage4.modulate = Color(0.4, 0.4, 0.4, 0.8)

	# Style Stage 5 Card
	if max_unlocked >= 5:
		btn_start5.disabled = false
		btn_start5.text = "进入关卡"
		card_stage5.modulate = Color(1.0, 1.0, 1.0, 1.0)
		if max_unlocked >= 6:
			# Stage 5 is cleared (Victory Game Over)
			lbl_header5.text = "第五关 (已通关)"
			lbl_header5.add_theme_color_override("font_color", Color(0.95, 0.8, 0.2))
			lbl_name5.add_theme_color_override("font_color", Color(0.95, 0.8, 0.2))
		else:
			lbl_header5.text = "第五关"
			lbl_header5.add_theme_color_override("font_color", Color(0.95, 0.45, 0.1))
	else:
		btn_start5.disabled = true
		btn_start5.text = "未解锁"
		lbl_header5.text = "第五关"
		card_stage5.modulate = Color(0.4, 0.4, 0.4, 0.8)

func _on_stage1_pressed():
	# Load level 1 while keeping current saved player stats if they exist
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_stage2_pressed():
	get_tree().change_scene_to_file("res://scenes/stage2.tscn")

func _on_stage3_pressed():
	get_tree().change_scene_to_file("res://scenes/stage3.tscn")

func _on_stage4_pressed():
	get_tree().change_scene_to_file("res://scenes/stage4.tscn")

func _on_stage5_pressed():
	get_tree().change_scene_to_file("res://scenes/stage5.tscn")

func _on_new_game_pressed():
	# Delete save file to start a completely brand new fresh game at level 1
	SaveSystem.delete_save()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_continue_pressed():
	var save_path = "user://rangers_path_save.json"
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		var text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		if json.parse(text) == OK:
			var data = json.get_data()
			# Set the static flag to tell stages to load stats exactly as-is without level reset
			SaveSystem.is_continuing = true
			
			# Determine which scene to load based on the stored level_index
			var lvl_index = data.get("level_index", 1)
			if lvl_index == 1:
				get_tree().change_scene_to_file("res://scenes/main.tscn")
			elif lvl_index == 2:
				get_tree().change_scene_to_file("res://scenes/stage2.tscn")
			elif lvl_index == 3:
				get_tree().change_scene_to_file("res://scenes/stage3.tscn")
			elif lvl_index == 4:
				get_tree().change_scene_to_file("res://scenes/stage4.tscn")
			elif lvl_index == 5:
				get_tree().change_scene_to_file("res://scenes/stage5.tscn")
			else:
				get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_quit_pressed():
	get_tree().quit()
