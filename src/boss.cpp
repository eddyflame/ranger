#include "boss.h"
#include "hero_player.h"
#include "game_manager.h"
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/packed_scene.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

namespace godot {

void Boss::_bind_methods() {
    ClassDB::bind_method(D_METHOD("cast_stomp"), &Boss::cast_stomp);
    ADD_SIGNAL(MethodInfo("boss_stomped", PropertyInfo(Variant::VECTOR2, "position"), PropertyInfo(Variant::FLOAT, "radius")));
}

Boss::Boss() {
    character_name = "Corrupted Treant (Boss)";
    level = 5;
    strength = 18;
    agility = 10;
    intelligence = 15;
    base_atk = 12.0f;
    base_def = 4.0f;
    move_speed = 90.0f;
    xp_reward = 450;
    
    aggro_range = 220.0f;
    attack_range = 65.0f;
    chase_limit = 450.0f;
    attack_rate = 1.8f;
}

Boss::~Boss() {}

void Boss::_ready() {
    Enemy::_ready();
    if (Engine::get_singleton()->is_editor_hint()) {
        return;
    }
    // Set boss dimensions or properties if needed
}

void Boss::_physics_process(double delta) {
    if (Engine::get_singleton()->is_editor_hint() || is_dead) {
        return;
    }

    // Call base class process for AI movement and basic attacks
    Enemy::_physics_process(delta);

    // Stomp timer
    if (stomp_timer > 0.0f) {
        stomp_timer -= delta;
    }

    // Boss Stomp Logic (target_node already validated by parent Enemy::_physics_process)
    if (target_node && (current_state == STATE_CHASE || current_state == STATE_ATTACK)) {
        float dist = get_global_position().distance_to(target_node->get_global_position());
        if (dist <= stomp_range && stomp_timer <= 0.0f) {
            cast_stomp();
            stomp_timer = stomp_cooldown;
        }
    }
}

void Boss::cast_stomp() {
    UtilityFunctions::print("Boss casts War Stomp!");
    emit_signal("boss_stomped", get_global_position(), stomp_range);
    
    // Play sound/animation visual effects via Godot nodes later
    
    // Apply area damage to player if in range
    HeroPlayer *player = Object::cast_to<HeroPlayer>(target_node);
    if (player) {
        float dist = get_global_position().distance_to(player->get_global_position());
        if (dist <= stomp_range) {
            player->take_damage(stomp_damage, this);
            
            // Apply a stun/slow effect or push player away
            Vector2 push_dir = (player->get_global_position() - get_global_position()).normalized();
            player->set_velocity(push_dir * 300.0f);
            player->move_and_slide();
        }
    }
}

void Boss::die() {
    Enemy::die(); // Spawn loot and award XP
}

} // namespace godot
