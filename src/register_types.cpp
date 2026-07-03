#include "register_types.h"

#include <gdextension_interface.h>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

#include "character.h"
#include "hero_player.h"
#include "enemy.h"
#include "boss.h"
#include "projectile.h"
#include "item_drop.h"
#include "game_manager.h"

using namespace godot;

void initialize_rpg_module(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
        return;
    }

    ClassDB::register_class<Character>();
    ClassDB::register_class<HeroPlayer>();
    ClassDB::register_class<Enemy>();
    ClassDB::register_class<Boss>();
    ClassDB::register_class<Projectile>();
    ClassDB::register_class<ItemDrop>();
    ClassDB::register_class<GameManager>();
}

void uninitialize_rpg_module(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
        return;
    }
}

#ifdef _WIN32
#define GDE_EXPORT __declspec(dllexport)
#else
#define GDE_EXPORT __attribute__((visibility("default")))
#endif

extern "C" {
// Initialization.
GDE_EXPORT GDExtensionBool GDExtensionInit(GDExtensionInterfaceGetProcAddress p_get_proc_address, const GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization) {
    godot::GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);

    init_obj.register_initializer(initialize_rpg_module);
    init_obj.register_terminator(uninitialize_rpg_module);
    init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);

    return init_obj.init();
}
}
