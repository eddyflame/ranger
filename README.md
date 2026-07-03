# Ranger – Godot 4 GDExtension RPG

## Overview
A lightweight 2‑D action‑RPG built with **Godot 4** and a **C++ GDExtension**.  The player (Archer) traverses multiple stages, defeats enemies, collects loot, upgrades stats, and unlocks new equipment.

## 🎮 Completed Features
- **ESC‑key menu** – press <kbd>Esc</kbd> to open the pause/shops UI.
- **Save system fix** – persistent saves now correctly store progress and level‑selection state.
- **Stage unlocking** – after clearing a stage its node lights up; players can replay any cleared stage from the level‑select screen.
- **Gold accumulation** – gold earned from loot and enemy drops persists across runs; gold is **not** reset on restart.
- **Rarity‑graded equipment** – items have grades **Common (⚪)**, **Uncommon (🟢)**, **Rare (🔵)**, **Epic (🟣)**, **Legendary (🟠)**.  Each grade rolls a number of bonus attributes (crit, lifesteal, evasion, block, speed, HP/MP bonuses).
- **Shop system** – buy/sell items at **50 %** of purchase price; white (common) items are hidden in the catalog but can still be recycled.
- **Attribute scaling** – weapons can grant **crit chance** and **lifesteal**; armors grant **evasion**, **block amount**, **speed**, **HP/MP** bonuses.
- **Combat mechanics**
  - **Critical hits** (2× damage) with floating "暴击" text and screen shake.
  - **Evasion** – fully avoid damage, showing a blue "闪避 (Evaded)!" text.
  - **Block** – reduce incoming damage by a flat amount, showing a "(格挡)" suffix.
- **Floating combat text** – damage numbers, critical, evasion, block, and XP gain all appear as animated floating labels.
- **Skill‑point system** – gaining a level awards one skill point; UI now refreshes the available points immediately after leveling.
- **Automatic resurrection** – Ankh of Reincarnation revives the player on death and is consumed.
- **Dynamic loot generation** – drops respect item grade and include random bonus attributes.
- **Visual polish** – modern dark UI, glowing rarity colors, scrollable shop, road/forest aesthetics.

## Project Structure
```
ranger/
├── .agents/               # project‑specific rules and style guide
├── src/                   # C++ source for GDExtension
│   ├── hero_player.h/.cpp
│   ├── character.h/.cpp
│   ├── enemy.h/.cpp
│   ├── boss.h/.cpp
│   ├── projectile.h/.cpp
│   └── register_types.*
├── project/               # Godot project root
│   ├── scenes/            # .tscn files + GDScript wrappers
│   │   ├── main.tscn
│   │   ├── hud.tscn / hud.gd
│   │   ├── stage2.tscn / stage2.gd
│   │   ├── stage3.tscn / stage3.gd
│   │   └── save_system.gd
│   ├── myrpg.gdextension # declares the compiled library path
│   └── project.godot      # Godot project config
├── SConstruct             # SCons build script (macOS template)
└── README.md              # <‑‑ **this file**
```

## Prerequisites
1. **macOS** (the repository is configured for macOS; Windows/Linux work with minor tweaks).
2. **Xcode Command‑Line Tools** – `xcode-select --install`
3. **Python 3** (for SCons) – `brew install python`
4. **SCons** – `pip3 install scons`
5. **Godot 4.7** (or newer) – download from https://godotengine.org
6. **Godot‑cpp bindings** – already vendored under `godot-cpp/`.

## Build the GDExtension (C++ Library)
Whenever you modify the C++ code, you must recompile the dynamic library. Open your terminal, navigate to the project directory, and build:

```bash
# Navigate to the repository root
cd path/to/ranger

# 1. Compile the C++ GDExtension library (Debug build)
scons platform=macos target=template_debug arch=x86_64 optimize=none -j12
```

This compiles your C++ classes and outputs the dynamic library:
* **Debug library:** `project/bin/libmyrpg.macos.template_debug.x86_64.dylib`
* **Configuration mapping:** `project/myrpg.gdextension` maps this library file so Godot automatically loads it.

---

## Running the Game

### 🚀 1. Direct Execution via Command Line (Bypasses Editor UI)
If you want to run the game directly without opening the Godot Editor:
```bash
# From the repository root
godot --path project
```
This directly launches the game window starting at the main menu.

### 🛠️ 2. Running via Godot Editor
1. Open the **Godot** engine launcher.
2. Select **Import**, browse to `project/project.godot` inside the repo, and open it.
3. You will see the Godot Editor workspace (which defaults to a 3D/2D viewport layout).
4. Run the project by:
   * Pressing <kbd>F5</kbd> on your keyboard.
   * Selecting **Debug → Run Project** from the top menu.
   * Clicking the **Play (▶)** button in the top-right corner.

### 📐 Window Resizing and Stretching
The game window stretch configuration in `project.godot` has been set to:
* **Base resolution:** `1280x720`
* **Mode:** `canvas_items` with aspect mode `expand`

This allows you to drag, maximize, or resize the game window freely; the UI and game content will scale and adapt seamlessly.

---

### 📦 3. Exporting a Standalone Executable (For players)
To generate a single, self-contained executable package:
1. In the Godot Editor, click **Project → Export**.
2. Add an export preset (e.g., macOS Desktop).
3. Click **Export Project** and choose the destination (e.g., `project/export/MyRPG.dmg`).
4. This packs the game code, GDExtension binary, and resources into a single distributable bundle.

## Where the Game Lives After Export
* **Development build** loads the library directly from `project/bin/`.
* **Exported builds** place the binary in `project/export/` along with `MyRPG.pck` containing all asset files.
* **User‑save data** is saved dynamically by Godot in your system's appdata folder:
  * **macOS:** `~/Library/Application Support/Godot/app_userdata/myrpg/rangers_path_save.json`

## Quick Testing Checklist
1. Run `scons ...` to compile GDExtension without compilation errors.
2. Run `godot --path project` to launch the game.
3. Verify:
   * ESC menu works.
   * Levels unlock correctly after victory.
   * Gold persists after re‑loading.
   * Items show correct rarity color and bonus tooltip.
   * Critical/Evasion/Block floating texts appear during combat.
   * Skill points increase on level‑up and UI updates instantly.
4. Drag and resize the game window to verify viewport scaling.

---
*Feel free to open an issue if any step fails or if you need platform‑specific tweaks.*
