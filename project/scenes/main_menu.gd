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
	
	# Create dynamic language switcher button in top right
	var btn_lang = Button.new()
	btn_lang.name = "BtnLanguage"
	btn_lang.custom_minimum_size = Vector2(160, 36)
	btn_lang.position = Vector2(1090, 20)
	btn_lang.pressed.connect(func():
		TranslationManager.toggle_locale()
	)
	add_child(btn_lang)
	
	TranslationManager.locale_changed.connect(refresh_translations)
	refresh_translations()

func refresh_translations():
	var btn_lang = get_node_or_null("BtnLanguage")
	if btn_lang:
		btn_lang.text = TranslationManager.t("MENU_LANG")
		
	$CenterContainer/VBox/TitleBox/Title.text = TranslationManager.t("MENU_TITLE")
	$CenterContainer/VBox/BottomRow/BtnNewGame.text = TranslationManager.t("MENU_NEW_GAME")
	$CenterContainer/VBox/BottomRow/BtnQuit.text = TranslationManager.t("MENU_QUIT")
	
	var max_unlocked = 1
	var save_path = "user://rangers_path_save.json"
	if FileAccess.file_exists(save_path):
		btn_continue.disabled = false
		btn_continue.text = TranslationManager.t("MENU_CONTINUE")
		
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
		btn_continue.text = TranslationManager.t("MENU_NO_SAVE")

	# Style Stage 1 Card (Always Unlocked)
	btn_start1.disabled = false
	btn_start1.text = TranslationManager.t("MENU_STAGE_ENTER")
	card_stage1.modulate = Color(1.0, 1.0, 1.0, 1.0)
	lbl_name1.text = TranslationManager.t("STAGE_1_NAME")
	$CenterContainer/VBox/LevelSelectRow/CardStage1/VBox/Desc.text = TranslationManager.t("STAGE_1_DESC")
	if max_unlocked >= 2:
		lbl_header1.text = TranslationManager.t("STAGE_1") + TranslationManager.t("STAGE_CLEARED")
		lbl_header1.add_theme_color_override("font_color", Color(0.95, 0.8, 0.2))
		lbl_name1.add_theme_color_override("font_color", Color(0.95, 0.8, 0.2))
	else:
		lbl_header1.text = TranslationManager.t("STAGE_1")
		lbl_header1.add_theme_color_override("font_color", Color(0.4, 0.7, 0.4))

	# Style Stage 2 Card
	lbl_name2.text = TranslationManager.t("STAGE_2_NAME")
	$CenterContainer/VBox/LevelSelectRow/CardStage2/VBox/Desc.text = TranslationManager.t("STAGE_2_DESC")
	if max_unlocked >= 2:
		btn_start2.disabled = false
		btn_start2.text = TranslationManager.t("MENU_STAGE_ENTER")
		card_stage2.modulate = Color(1.0, 1.0, 1.0, 1.0)
		if max_unlocked >= 3:
			lbl_header2.text = TranslationManager.t("STAGE_2") + TranslationManager.t("STAGE_CLEARED")
			lbl_header2.add_theme_color_override("font_color", Color(0.95, 0.8, 0.2))
			lbl_name2.add_theme_color_override("font_color", Color(0.95, 0.8, 0.2))
		else:
			lbl_header2.text = TranslationManager.t("STAGE_2")
			lbl_header2.add_theme_color_override("font_color", Color(0.4, 0.7, 0.8))
	else:
		btn_start2.disabled = true
		btn_start2.text = TranslationManager.t("MENU_STAGE_LOCKED")
		lbl_header2.text = TranslationManager.t("STAGE_2")
		card_stage2.modulate = Color(0.4, 0.4, 0.4, 0.8)

	# Style Stage 3 Card
	lbl_name3.text = TranslationManager.t("STAGE_3_NAME")
	$CenterContainer/VBox/LevelSelectRow/CardStage3/VBox/Desc.text = TranslationManager.t("STAGE_3_DESC")
	if max_unlocked >= 3:
		btn_start3.disabled = false
		btn_start3.text = TranslationManager.t("MENU_STAGE_ENTER")
		card_stage3.modulate = Color(1.0, 1.0, 1.0, 1.0)
		if max_unlocked >= 4:
			lbl_header3.text = TranslationManager.t("STAGE_3") + TranslationManager.t("STAGE_CLEARED")
			lbl_header3.add_theme_color_override("font_color", Color(0.95, 0.8, 0.2))
			lbl_name3.add_theme_color_override("font_color", Color(0.95, 0.8, 0.2))
		else:
			lbl_header3.text = TranslationManager.t("STAGE_3")
			lbl_header3.add_theme_color_override("font_color", Color(0.85, 0.45, 1.0))
	else:
		btn_start3.disabled = true
		btn_start3.text = TranslationManager.t("MENU_STAGE_LOCKED")
		lbl_header3.text = TranslationManager.t("STAGE_3")
		card_stage3.modulate = Color(0.4, 0.4, 0.4, 0.8)

	# Style Stage 4 Card
	lbl_name4.text = TranslationManager.t("STAGE_4_NAME")
	$CenterContainer/VBox/LevelSelectRow/CardStage4/VBox/Desc.text = TranslationManager.t("STAGE_4_DESC")
	if max_unlocked >= 4:
		btn_start4.disabled = false
		btn_start4.text = TranslationManager.t("MENU_STAGE_ENTER")
		card_stage4.modulate = Color(1.0, 1.0, 1.0, 1.0)
		if max_unlocked >= 5:
			lbl_header4.text = TranslationManager.t("STAGE_4") + TranslationManager.t("STAGE_CLEARED")
			lbl_header4.add_theme_color_override("font_color", Color(0.95, 0.8, 0.2))
			lbl_name4.add_theme_color_override("font_color", Color(0.95, 0.8, 0.2))
		else:
			lbl_header4.text = TranslationManager.t("STAGE_4")
			lbl_header4.add_theme_color_override("font_color", Color(1.0, 0.6, 0.1))
	else:
		btn_start4.disabled = true
		btn_start4.text = TranslationManager.t("MENU_STAGE_LOCKED")
		lbl_header4.text = TranslationManager.t("STAGE_4")
		card_stage4.modulate = Color(0.4, 0.4, 0.4, 0.8)

	# Style Stage 5 Card
	lbl_name5.text = TranslationManager.t("STAGE_5_NAME")
	$CenterContainer/VBox/LevelSelectRow/CardStage5/VBox/Desc.text = TranslationManager.t("STAGE_5_DESC")
	if max_unlocked >= 5:
		btn_start5.disabled = false
		btn_start5.text = TranslationManager.t("MENU_STAGE_ENTER")
		card_stage5.modulate = Color(1.0, 1.0, 1.0, 1.0)
		if max_unlocked >= 6:
			lbl_header5.text = TranslationManager.t("STAGE_5") + TranslationManager.t("STAGE_CLEARED")
			lbl_header5.add_theme_color_override("font_color", Color(0.95, 0.8, 0.2))
			lbl_name5.add_theme_color_override("font_color", Color(0.95, 0.8, 0.2))
		else:
			lbl_header5.text = TranslationManager.t("STAGE_5")
			lbl_header5.add_theme_color_override("font_color", Color(0.95, 0.45, 0.1))
	else:
		btn_start5.disabled = true
		btn_start5.text = TranslationManager.t("MENU_STAGE_LOCKED")
		lbl_header5.text = TranslationManager.t("STAGE_5")
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
