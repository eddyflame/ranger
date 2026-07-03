# Ranger's Path (Godot 4 + GDExtension C++)

A high-performance Action RPG (ARPG) built with **Godot Engine 4** and **GDExtension (C++17)**. The gameplay and mechanics (such as unit attributes, armor formulas, and AI return/healing behavior) are inspired by classic RTS and RPG mechanics.

---

## 🎮 Game Controls & Objectives

### Objective
Explore the map, fight wolves to gain experience points (XP), collect items/potions to increase your stats, and defeat the **Corrupted Treant (Boss)** at the far right of the map to win the stage!

### Controls
* **Right-Click**: Command the player to move to a destination, attack an enemy, or pick up a ground item.
* **Q Key / Skill Button Q**: Toggle **Searing Arrows** (adds bonus damage to basic attacks at the cost of Mana).
* **W Key / Skill Button W**: Cast **Windwalk** (makes the player invisible, increases movement speed, and drops enemy aggro).
* **Inventory Click**: Use items (e.g., healing potions) from your 6-slot inventory bar at the bottom.

---

## 📁 Codebase Architecture

The project is structured to split engine-side configuration and assets from performance-critical gameplay logic implemented in native C++:

```
myrpg/
├── src/                    # C++ Source Code (GDExtension)
│   ├── register_types.h/cpp # GDExtension registration entrypoint
│   ├── character.h/cpp      # Base Character class (stats, attributes, health/mana)
│   ├── hero_player.h/cpp    # Archer Player class (input, skills, inventory)
│   ├── enemy.h/cpp          # Chase & Attack AI (Wolf)
│   ├── boss.h/cpp           # Boss AI (Corrupted Treant) with AoE Stomp
│   ├── projectile.h/cpp     # Arrow physics & target homing
│   ├── item_drop.h/cpp      # Physical items dropped on map
│   └── game_manager.h/cpp   # Game manager node (victory/defeat state)
├── project/                # Godot Project Root
│   ├── bin/                 # Compiled GDExtension dynamic libraries
│   ├── scenes/              # Game Scenes & GDScript wrappers
│   │   ├── main.tscn/gd     # Stage 1 Level map and setup script
│   │   ├── hud.tscn/gd      # UI, status indicators, inventory, and skills
│   │   ├── player.tscn      # Player node instantiation
│   │   ├── enemy.tscn       # Enemy node instantiation
│   │   ├── boss.tscn        # Boss node instantiation
│   │   └── item_drop.tscn   # Ground items instantiation
│   ├── myrpg.gdextension    # GDExtension configuration file
│   └── project.godot        # Godot Engine Settings
├── SConstruct              # SCons Build script (for macOS templates)
└── build_profile.json      # SCons optimization configuration
```

---

## 🛠️ Build & Compilation

To build and compile the GDExtension native C++ library, you will need **SCons** and a compatible C++17 compiler (GCC/Clang/MSVC).

### Prerequisites
1. Install [SCons](https://scons.org/).
2. Clone this repository with submodules (for the `godot-cpp` bindings):
   ```bash
   git clone --recursive <repository-url>
   ```

### Compile on macOS
Run the SCons build system command:
```bash
scons platform=macos target=template_debug arch=x86_64 optimize=none -j12
```

### Run the Game
Open the project using the Godot 4 Editor, or run it directly from the command line:
```bash
godot --path project
```

---

## ⚙️ Key Mechanics (C++ Code Specs)

* **Attributes Modifiers**:
  * Max HP: `max_hp + strength * 20.0f`
  * Max MP: `max_mp + intelligence * 15.0f`
  * Base Attack: `base_atk + agility * 1.0f`
  * Base Defense: `base_def + agility * 0.15f`
* **Armor Formula**:
  * Damage multiplier: `multiplier = 20.0f / (20.0f + total_def)` (where positive defense reduces incoming damage).
* **Creep AI Return**:
  * Wolves and the Boss chase the player up to a designated `chase_limit` distance from their home coordinates. If exceeded, they drop aggro, return to their spawn coordinates, and heal back to full health.
