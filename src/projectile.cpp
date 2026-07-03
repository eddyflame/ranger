#include "projectile.h"
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/cpu_particles2d.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

namespace godot {

void Projectile::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_target", "target"), &Projectile::set_target);
    ClassDB::bind_method(D_METHOD("get_target"), &Projectile::get_target);

    ClassDB::bind_method(D_METHOD("set_speed", "speed"), &Projectile::set_speed);
    ClassDB::bind_method(D_METHOD("get_speed"), &Projectile::get_speed);

    ClassDB::bind_method(D_METHOD("set_damage", "damage"), &Projectile::set_damage);
    ClassDB::bind_method(D_METHOD("get_damage"), &Projectile::get_damage);

    ClassDB::bind_method(D_METHOD("set_searing_effect", "searing"), &Projectile::set_searing_effect);
    ClassDB::bind_method(D_METHOD("get_searing_effect"), &Projectile::get_searing_effect);
}

Projectile::Projectile() {}

Projectile::~Projectile() {}

void Projectile::_physics_process(double delta) {
    if (Engine::get_singleton()->is_editor_hint()) {
        return;
    }

    if (target && !target->is_queued_for_deletion()) {
        Vector2 target_pos = target->get_global_position();
        Vector2 current_pos = get_global_position();
        
        Vector2 diff = target_pos - current_pos;
        float dist = diff.length();
        
        last_direction = diff.normalized();
        
        if (dist <= speed * delta) {
            // Hit!
            if (target->has_method("take_damage")) {
                target->call("take_damage", damage, attacker);
            }
            queue_free();
        } else {
            // Move towards target
            set_global_position(current_pos + last_direction * speed * delta);
            // Face the target
            set_rotation(last_direction.angle());
        }
    } else {
        // Target lost, continue moving in last direction and fade out
        Vector2 current_pos = get_global_position();
        set_global_position(current_pos + last_direction * speed * delta);
        
        // Simple timeout/distance self-destruction
        static float lifetime = 1.0f;
        lifetime -= delta;
        if (lifetime <= 0.0f) {
            queue_free();
        }
    }
}

void Projectile::_ready() {
    if (Engine::get_singleton()->is_editor_hint()) {
        return;
    }
    Node *particles = get_node<Node>("FireParticles");
    if (particles) {
        particles->set("emitting", is_searing);
    }
}

void Projectile::set_searing_effect(bool p_searing) {
    is_searing = p_searing;
    if (is_inside_tree()) {
        Node *particles = get_node<Node>("FireParticles");
        if (particles) {
            particles->set("emitting", p_searing);
        }
    }
}

} // namespace godot
