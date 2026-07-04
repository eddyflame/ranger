#include "abyss_boss.h"
#include "hero_player.h"
#include "projectile.h"
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/packed_scene.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/world2d.hpp>
#include <godot_cpp/classes/navigation_server2d.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

namespace godot {

void AbyssBoss::_bind_methods() {
    ClassDB::bind_method(D_METHOD("get_current_phase"), &AbyssBoss::get_current_phase);
    ClassDB::bind_method(D_METHOD("set_current_phase", "phase"), &AbyssBoss::set_current_phase);
    ClassDB::bind_method(D_METHOD("cast_dark_bolt", "direction"), &AbyssBoss::cast_dark_bolt);
    ClassDB::bind_method(D_METHOD("teleport_away"), &AbyssBoss::teleport_away);

    ADD_SIGNAL(MethodInfo("phase_transition_started"));
}

AbyssBoss::AbyssBoss() {
    character_name = "Abyss Mage (Boss)";
    level = 13;
    strength = 25;
    agility = 20;
    intelligence = 60;
    base_atk = 20.0f;
    base_def = 8.0f;
    move_speed = 110.0f;
    xp_reward = 2000;

    aggro_range = 400.0f;
    attack_range = 250.0f; // Ranged boss
    chase_limit = 600.0f;
    attack_rate = 1.4f;

    current_phase = 1;
}

AbyssBoss::~AbyssBoss() {}

void AbyssBoss::_ready() {
    Boss::_ready();
    // Start with a dark blue/purple modulation tint for the Abyss Mage style
    set_modulate(Color(0.5f, 0.4f, 0.9f, 1.0f));
}

void AbyssBoss::_physics_process(double delta) {
    if (Engine::get_singleton()->is_editor_hint() || is_dead) {
        return;
    }

    // Call base class process for general chasing and target checking
    Boss::_physics_process(delta);

    // Keep Phase 2 modulation and immunity
    if (current_phase == 2) {
        slow_timer = 0.0f;
        set_modulate(Color(1.0f, 0.25f, 0.25f, 1.0f));
    }

    // Tick combat timers
    if (teleport_timer > 0.0f) {
        teleport_timer -= delta;
    }
    if (spit_timer > 0.0f) {
        spit_timer -= delta;
    }
    if (stomp_timer > 0.0f) {
        stomp_timer -= delta;
    }

    // Attack routines if target is close
    if (target_node && (current_state == STATE_CHASE || current_state == STATE_ATTACK)) {
        float dist = get_global_position().distance_to(target_node->get_global_position());
        if (dist <= aggro_range) {
            // Phase 1 (Mage): Teleport away if player gets too close
            if (current_phase == 1 && dist < 120.0f && teleport_timer <= 0.0f) {
                teleport_away();
                teleport_timer = teleport_cooldown;
            }

            // Projectile spit timer
            if (spit_timer <= 0.0f) {
                Vector2 dir = (target_node->get_global_position() - get_global_position()).normalized();
                
                if (current_phase == 1) {
                    // Phase 1: single dark bolt
                    cast_dark_bolt(dir);
                } else {
                    // Phase 2: multi-shot fan (3 bolts spread by 15 degrees)
                    cast_dark_bolt(dir);
                    cast_dark_bolt(dir.rotated(Math_PI / 12.0f));  // +15 deg
                    cast_dark_bolt(dir.rotated(-Math_PI / 12.0f)); // -15 deg
                }
                
                spit_timer = spit_cooldown;
            }

            // Phase 2 (Dragon): Stomp and Screen Shake if in close range
            if (current_phase == 2 && dist <= 160.0f && stomp_timer <= 0.0f) {
                cast_stomp();
                stomp_timer = stomp_cooldown;
                
                // Trigger screen shake on target player
                HeroPlayer *player = Object::cast_to<HeroPlayer>(target_node);
                if (player) {
                    player->trigger_shake(8.0f, 0.4f);
                }
            }
        }
    }
}

void AbyssBoss::cast_dark_bolt(Vector2 direction) {
    Ref<PackedScene> dark_proj_scene = ResourceLoader::get_singleton()->load("res://scenes/dark_projectile.tscn");
    if (dark_proj_scene.is_valid()) {
        Node *inst = dark_proj_scene->instantiate();
        Projectile *proj = Object::cast_to<Projectile>(inst);
        if (proj) {
            proj->set_global_position(get_global_position() + direction * 35.0f);
            proj->set_target(target_node);
            proj->set_attacker(this);
            proj->set_damage(base_atk * 0.9f); // 90% attack damage
            proj->set_speed(current_phase == 1 ? 300.0f : 360.0f);
            get_parent()->add_child(proj);
        }
    }
}

void AbyssBoss::teleport_away() {
    // Generate random angle, select offset spot at 200px distance
    float angle = UtilityFunctions::randf() * Math_PI * 2.0f;
    Vector2 offset = Vector2(std::cos(angle), std::sin(angle)) * 200.0f;
    Vector2 target_pos = get_global_position() + offset;

    // Map to navigation walkable closest point
    RID map = get_world_2d()->get_navigation_map();
    Vector2 walkable = NavigationServer2D::get_singleton()->map_get_closest_point(map, target_pos);
    
    // Play transition visual indicator (e.g. print console, reset position)
    UtilityFunctions::print("Abyss Mage blinks to: ", walkable);
    set_global_position(walkable);
}

void AbyssBoss::die() {
    if (current_phase == 1) {
        // Transition to Phase 2: Abyss Overlord
        current_phase = 2;
        is_dead = false;
        
        character_name = "Abyss Overlord (Phase 2)";
        
        // Full health restore and stats boost
        set_max_hp(1200.0f);
        set_hp(1200.0f);
        set_base_atk(75.0f);
        set_base_def(15.0f);
        set_move_speed(180.0f);
        
        // Visual updates
        set_scale(Vector2(2.5f, 2.5f));
        set_modulate(Color(1.0f, 0.2f, 0.2f, 1.0f));
        
        // Emit dynamic transition signal for camera shake / main script callbacks
        emit_signal("phase_transition_started");
        UtilityFunctions::print("Abyss Mage has awakened into Abyss Overlord Phase 2!");
    } else {
        // True Boss death
        Boss::die();
    }
}

} // namespace godot
