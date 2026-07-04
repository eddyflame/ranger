extends Node

signal locale_changed

const SAVE_PATH = "user://rangers_path_save.json"

var current_locale: String = "en" # Default to English

var dictionary := {
	"MENU_TITLE": { "en": "Ranger's Path", "zh": "游侠之路" },
	"MENU_SUBTITLE": { "en": "R A N G E R ' S   P A T H", "zh": "游 侠 之 路" },
	"MENU_NEW_GAME": { "en": "New Game (Reset Progress)", "zh": "新游戏 (重置进度)" },
	"MENU_CONTINUE": { "en": "Continue Game", "zh": "继续上次游戏" },
	"MENU_NO_SAVE": { "en": "No Save File Found", "zh": "暂无存档" },
	"MENU_QUIT": { "en": "Quit Game", "zh": "退出游戏" },
	"MENU_STAGE_ENTER": { "en": "Enter Stage", "zh": "进入关卡" },
	"MENU_STAGE_LOCKED": { "en": "Locked", "zh": "未解锁" },
	"MENU_LANG": { "en": "Language: English", "zh": "语言: 简体中文" },
	
	# Stages UI
	"STAGE_1": { "en": "Stage 1", "zh": "第一关" },
	"STAGE_2": { "en": "Stage 2", "zh": "第二关" },
	"STAGE_3": { "en": "Stage 3", "zh": "第三关" },
	"STAGE_4": { "en": "Stage 4", "zh": "第四关" },
	"STAGE_5": { "en": "Stage 5", "zh": "第五关" },
	"STAGE_CLEARED": { "en": " (Cleared)", "zh": " (已通关)" },
	
	"STAGE_1_NAME": { "en": "Forest Path", "zh": "森林小径" },
	"STAGE_1_DESC": { "en": "Start the journey!\nRec. Level: 1+", "zh": "开启冒险之旅！\n推荐等级: 1级+" },
	"STAGE_2_NAME": { "en": "Spider Cave", "zh": "地狱蜘蛛洞" },
	"STAGE_2_DESC": { "en": "Dark cave of spiders!\nRec. Level: 3+", "zh": "阴暗潮湿 the 洞穴！\n推荐等级: 3级+" },
	"STAGE_3_NAME": { "en": "Ancient Ruins", "zh": "遗迹古树" },
	"STAGE_3_DESC": { "en": "Beware of ancient tree!\nRec. Level: 6+", "zh": "古老的森灵遗迹！\n推荐等级: 6级+" },
	"STAGE_4_NAME": { "en": "Spider Nest", "zh": "深渊蛛巢" },
	"STAGE_4_DESC": { "en": "Lair of the Queen!\nRec. Level: 9+", "zh": "深渊蛛后的巢穴！\n推荐等级: 9级+" },
	"STAGE_5_NAME": { "en": "Volcano Summit", "zh": "火山之巅" },
	"STAGE_5_DESC": { "en": "Final Overlord showdown!\nRec. Level: 12+", "zh": "决战深渊魔主！\n推荐等级: 12级+" },

	# HUD Panel headers
	"HUD_STAGE_QUESTS": { "en": "Stage Quests", "zh": "当前阶段任务" },
	"HUD_ATTRIBUTES": { "en": "Attributes", "zh": "角色属性" },
	"HUD_TALENTS": { "en": "Passive Talents", "zh": "被动天赋 (Talents)" },
	"HUD_TALENT_POINTS": { "en": "Talent Points: ", "zh": "可用天赋点: " },
	"HUD_SKILL_POINTS": { "en": "Available Points: ", "zh": "可用点数: " },
	"HUD_GOLD_HELD": { "en": "Your Gold: %d", "zh": "您的金币: %d" },
	"HUD_GOLD": { "en": "Gold: ", "zh": "金币: " },
	"HUD_VICTORY": { "en": "Victory! Stage Cleared", "zh": "胜利！本关已通过" },
	"HUD_DEFEAT": { "en": "GAME OVER", "zh": "游戏结束" },
	"HUD_REPLAY": { "en": "Replay (Reset Stats)", "zh": "重玩本关 (Reset Stats)" },
	"HUD_PLAY_AGAIN": { "en": "Play Again", "zh": "重玩本关 (Replay)" },
	"HUD_NEXT_STAGE": { "en": "Next Stage", "zh": "下一关" },
	"HUD_RESTART_GAME": { "en": "Restart Game", "zh": "重新开始游戏" },
	"HUD_RETURN_MENU": { "en": "Main Menu", "zh": "返回主菜单" },
	"HUD_REVIVE_SPOT": { "en": "Revive at Spot (Keep Stats)", "zh": "原地复活 (Keep Stats)" },
	"HUD_REVIVE_BASE": { "en": "Revive at Base (Keep Stats)", "zh": "起点复活 (Keep Stats)" },
	
	# Skills UI
	"SKILL_NOT_LEARNED": { "en": "Locked", "zh": "未学习" },
	"SKILL_Q_NAME": { "en": "Searing Arrow", "zh": "炽热箭" },
	"SKILL_W_NAME": { "en": "Windwalk", "zh": "疾风步" },
	"SKILL_E_NAME": { "en": "Blink", "zh": "闪烁" },
	"SKILL_R_NAME": { "en": "Arrow Rain", "zh": "箭雨" },
	
	# Shop
	"SHOP_TITLE": { "en": "Merchant Shop & Forge", "zh": "神秘商店与强化工坊 (Shop & Upgrades)" },
	"SHOP_BUY": { "en": "Shop Items", "zh": "购买商品 (Shop Items)" },
	"SHOP_UPGRADE": { "en": "Upgrade Gear", "zh": "装备强化 (Upgrade Gear)" },
	"SHOP_CLOSE": { "en": "Close Shop", "zh": "关闭商店" },
	"SHOP_BUY_BTN": { "en": "Buy", "zh": "购买" },
	"SHOP_MAX_UPGRADE": { "en": "Fully Reinforced", "zh": "已强化至上限" },
	"SHOP_UPGRADE_BTN": { "en": "Upgrade", "zh": "强化 (升级)" },
	"SHOP_UPGRADE_SUCCESS": { "en": "✓ Upgrade success: %s -> +%d!", "zh": "✓ 强化成功：%s -> +%d!" },
	"SHOP_NO_GOLD": { "en": "Not enough gold!", "zh": "金币不足，无法强化！" },
	"SHOP_MAXED": { "en": "Item is already fully upgraded!", "zh": "该装备已达到最高强化等级！" },
	"SHOP_ITEM_COST": { "en": "Cost: %d Gold", "zh": "价格: %d 金币" },
	"SHOP_MAXED_PREVIEW": { "en": "【Max upgraded】", "zh": "【已强化至上限】" },
	"SHOP_NEXT_ATK": { "en": "Next -> ATK: +%d", "zh": "强化后 -> 攻击: +%d" },
	"SHOP_NEXT_ARMOR": { "en": "Next -> DEF: +%d\nHP: +%d", "zh": "Next -> DEF: +%d\nHP: +%d" },
	"SHOP_UPGRADE_COST_MAX": { "en": "Max Level", "zh": "最高等级" },
	
	# Floating & Alerts
	"ALERT_CRIT": { "en": "Crit ", "zh": "暴击 " },
	"ALERT_BLOCKED": { "en": " (Blocked)", "zh": " (格挡)" },
	"ALERT_EVADED": { "en": "Evaded!", "zh": "闪避!" },
	"ALERT_SLOWED": { "en": "Slowed!", "zh": "减速!" },
	"ALERT_STOMPED": { "en": "Stomped!", "zh": "震地撞击!" },
	"ALERT_PORTAL_OPEN": { "en": "★ Exit Portal Opened ★", "zh": "★ 通关传送门已开启 ★" },
	"ALERT_STAGE1_BOSS_VICTORY": { "en": "🎉 Lord Defeated! Portal Opened", "zh": "🎉 领主已击败！通关传送门已开启" },
	"ALERT_STAGE5_BOSS_VICTORY": { "en": "🎉 Overlord Slain! Final Portal Opened", "zh": "🎉 最终魔王已伏诛！最终通关传送门已开启" },
	
	# Quest Banners
	"BANNER_ACHIEVEMENT": { "en": "🏆 Achievement Unlocked!", "zh": "🏆 达成成就！" },
	"Q_COMPLETED_STATUS": { "en": " (Completed)", "zh": " (已完成)" },
	
	# Quests Descriptions
	"消灭森林魔狼": { "en": "Defeat Forest Wolves", "zh": "消灭森林魔狼" },
	"向商人购买1瓶治疗药水": { "en": "Buy 1 Healing Potion", "zh": "向商人购买1瓶治疗药水" },
	"消灭洞穴地狱蜘蛛": { "en": "Defeat Cave Spiders", "zh": "消灭洞穴地狱蜘蛛" },
	"击败腐化古树特兰特": { "en": "Defeat Corrupted Treant", "zh": "击败腐化古树特兰特" },
	"消灭深渊蛛后护卫": { "en": "Defeat Nest Protectors", "zh": "消灭深渊蛛后护卫" },
	"击败终极深渊魔主": { "en": "Defeat final Overlord", "zh": "击败终极深渊魔主" },
	
	# Direct string mappings for floating messages
	"闪避 (Evaded)!": { "en": "Evaded!", "zh": "闪避 (Evaded)!" },
	"减速 (Slowed)!": { "en": "Slowed!", "zh": "减速 (Slowed)!" },
	"💥 震地撞击 (Stomped)!": { "en": "💥 Stomped!", "zh": "💥 震地撞击 (Stomped)!" },
	"★ 传送门已开启 ★": { "en": "★ Exit Portal Opened ★", "zh": "★ 传送门已开启 ★" },
	"👼 复活重生！": { "en": "👼 Resurrected!", "zh": "👼 复活重生！" },
	"💾 游戏已手动保存！": { "en": "💾 Game saved!", "zh": "💾 游戏已手动保存！" },
	"👼 原地复活！": { "en": "👼 Revived on spot!", "zh": "👼 原地复活！" },
	"🎉 领主已击败！通关传送门已开启": { "en": "🎉 Boss defeated! Exit portal opened", "zh": "🎉 领主已击败！通关传送门已开启" },
	"🎉 最终魔王已伏诛！最终通关传送门已开启": { "en": "🎉 Final boss defeated! Exit portal opened", "zh": "🎉 最终魔王已伏诛！最终通关传送门已开启" },
	"👿 怪物复活！": { "en": "👿 Monsters Respawned!", "zh": "👿 怪物复活！" },
	"🔥 【深渊魔王觉醒！】 🔥": { "en": "🔥 Overlord Awakened! Phase 2! 🔥", "zh": "🔥 【深渊魔王觉醒！】 🔥" },
	"⚠️ 【第二阶段：魔王之躯！】": { "en": "⚠️ Phase 2: Ultimate Form!", "zh": "⚠️ 【第二阶段：魔王之躯！】" },
	"治疗药水": { "en": "Potion of Healing", "zh": "治疗药水" },
	"复活十字架": { "en": "Ankh of Reincarnation", "zh": "复活十字架" },
	"FINAL_STAGE_CONGRATS": { "en": "Congratulations! You saved Ranger's Path!", "zh": "恭喜通关游侠之路！" }
}

func _ready():
	load_settings()

func t(key: String) -> String:
	if not dictionary.has(key):
		return key
	return dictionary[key].get(current_locale, key)

func toggle_locale():
	current_locale = "zh" if current_locale == "en" else "en"
	save_settings()
	locale_changed.emit()

func save_settings():
	var save_data := {}
	if FileAccess.file_exists(SAVE_PATH):
		var file_read = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file_read:
			var old_text = file_read.get_as_text()
			file_read.close()
			var json_old = JSON.new()
			if json_old.parse(old_text) == OK:
				var old_data = json_old.get_data()
				if typeof(old_data) == TYPE_DICTIONARY:
					save_data = old_data
					
	save_data["locale"] = current_locale
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()

func load_settings():
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json_string = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(json_string) == OK:
		var save_data = json.data
		if typeof(save_data) == TYPE_DICTIONARY:
			current_locale = save_data.get("locale", "en")
