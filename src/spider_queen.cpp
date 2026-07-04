#include "spider_queen.h"
#include "hero_player.h"
#include "projectile.h"
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/packed_scene.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

namespace godot {

void SpiderQueen::_bind_methods() {
    ClassDB::bind_method(D_METHOD("summon_spiderlings"), &SpiderQueen::summon_spiderlings);
    ClassDB::bind_method(D_METHOD("spit_web"), &SpiderQueen::spit_web);

    // Register minion_spawned signal so stage script can connect dynamic minion signals
    ADD_SIGNAL(MethodInfo("minion_spawned", PropertyInfo(Variant::OBJECT, "minion")));
}

SpiderQueen::SpiderQueen() {
    character_name = "Spider Queen (Boss)";
    level = 7;
    strength = 22;
    agility = 15;
    intelligence = 25;
    base_atk = 16.0f;
    base_def = 6.0f;
    move_speed = 100.0f;
    xp_reward = 800;

    aggro_range = 300.0f;
    attack_range = 100.0f;
    chase_limit = 500.0f;
    attack_rate = 1.6f;
}

SpiderQueen::~SpiderQueen() {}

void SpiderQueen::_ready() {
    Boss::_ready();
}

void SpiderQueen::_physics_process(double delta) {
    if (Engine::get_singleton()->is_editor_hint() || is_dead) {
        return;
    }

    // Call base class process for AI movement and basic stomp/attacks
    Boss::_physics_process(delta);

    // Manage summon and spit timers
    if (summon_timer > 0.0f) {
        summon_timer -= delta;
    }
    if (spit_timer > 0.0f) {
        spit_timer -= delta;
    }

    // Spider Queen unique combat skills
    if (target_node && (current_state == STATE_CHASE || current_state == STATE_ATTACK)) {
        float dist = get_global_position().distance_to(target_node->get_global_position());
        if (dist <= aggro_range) {
            if (summon_timer <= 0.0f) {
                summon_spiderlings();
                summon_timer = summon_cooldown;
            }
            if (spit_timer <= 0.0f) {
                spit_web();
                spit_timer = spit_cooldown;
            }
        }
    }
}

void SpiderQueen::summon_spiderlings() {
    UtilityFunctions::print("Spider Queen casts Summon Spiderlings!");
    Ref<PackedScene> minion_scene = ResourceLoader::get_singleton()->load("res://scenes/spiderling.tscn");
    if (minion_scene.is_valid()) {
        for (int i = 0; i < 2; ++i) {
            Node *inst = minion_scene->instantiate();
            Node2D *minion = Object::cast_to<Node2D>(inst);
            if (minion) {
                // Spawn slightly offset from Spider Queen position
                Vector2 offset = Vector2(UtilityFunctions::randf_range(-50.0f, 50.0f), UtilityFunctions::randf_range(-50.0f, 50.0f));
                minion->set_global_position(get_global_position() + offset);
                get_parent()->add_child(minion);

                // Emit signal so level script connects floating text/damage signals
                emit_signal("minion_spawned", minion);
            }
        }
    }
}

void SpiderQueen::spit_web() {
    UtilityFunctions::print("Spider Queen casts Web Spit!");
    Ref<PackedScene> web_scene = ResourceLoader::get_singleton()->load("res://scenes/web_projectile.tscn");
    if (web_scene.is_valid()) {
        Node *inst = web_scene->instantiate();
        Projectile *proj = Object::cast_to<Projectile>(inst);
        if (proj) {
            Vector2 dir = (target_node->get_global_position() - get_global_position()).normalized();
            proj->set_global_position(get_global_position() + dir * 30.0f);
            proj->set_target(target_node);
            proj->set_attacker(this);
            proj->set_damage(base_atk * 0.8f); // 80% attack damage
            proj->set_speed(300.0f);
            proj->set_web_effect(true);
            get_parent()->add_child(proj);
        }
    }
}

void SpiderQueen::die() {
    Boss::die(); // Triggers exit portal spawn, base loot generation, and XP award
}

} // namespace godot
