#include "game_manager.h"
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

namespace godot {

GameManager *GameManager::singleton = nullptr;

void GameManager::_bind_methods() {
    ClassDB::bind_method(D_METHOD("trigger_victory"), &GameManager::trigger_victory);
    ClassDB::bind_method(D_METHOD("trigger_game_over"), &GameManager::trigger_game_over);
    ClassDB::bind_method(D_METHOD("get_is_victory"), &GameManager::get_is_victory);
    ClassDB::bind_method(D_METHOD("get_is_gameover"), &GameManager::get_is_gameover);
    ClassDB::bind_method(D_METHOD("restart_game"), &GameManager::restart_game);

    // Signals
    ADD_SIGNAL(MethodInfo("game_victory"));
    ADD_SIGNAL(MethodInfo("game_over"));
}

GameManager::GameManager() {
    if (singleton == nullptr) {
        singleton = this;
    }
}

GameManager::~GameManager() {
    if (singleton == this) {
        singleton = nullptr;
    }
}

void GameManager::_ready() {
    if (Engine::get_singleton()->is_editor_hint()) {
        return;
    }
    is_victory = false;
    is_gameover = false;
}

void GameManager::_exit_tree() {
    if (singleton == this) {
        singleton = nullptr;
    }
}

void GameManager::trigger_victory() {
    if (is_victory || is_gameover) return;
    is_victory = true;
    UtilityFunctions::print("Victory! Stage Cleared.");
    emit_signal("game_victory");
}

void GameManager::trigger_game_over() {
    if (is_victory || is_gameover) return;
    is_gameover = true;
    UtilityFunctions::print("Game Over. You Died.");
    emit_signal("game_over");
}

void GameManager::restart_game() {
    is_victory = false;
    is_gameover = false;
    get_tree()->reload_current_scene();
}

} // namespace godot
