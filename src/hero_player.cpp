#include "hero_player.h"
#include "projectile.h"
#include "item_drop.h"
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/node2d.hpp>
#include <godot_cpp/classes/cpu_particles2d.hpp>
#include <godot_cpp/classes/world2d.hpp>
#include <godot_cpp/classes/physics_direct_space_state2d.hpp>
#include <godot_cpp/classes/physics_point_query_parameters2d.hpp>
#include <godot_cpp/classes/input_event_mouse_button.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/packed_scene.hpp>
#include <godot_cpp/classes/viewport.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

namespace godot {

void HeroPlayer::_bind_methods() {
    ClassDB::bind_method(D_METHOD("add_xp", "xp"), &HeroPlayer::add_xp);
    ClassDB::bind_method(D_METHOD("get_xp"), &HeroPlayer::get_xp);
    ClassDB::bind_method(D_METHOD("get_xp_to_next_level"), &HeroPlayer::get_xp_to_next_level);
    ClassDB::bind_method(D_METHOD("get_skill_points"), &HeroPlayer::get_skill_points);

    ClassDB::bind_method(D_METHOD("get_inventory"), &HeroPlayer::get_inventory);
    ClassDB::bind_method(D_METHOD("add_to_inventory", "item"), &HeroPlayer::add_to_inventory);
    ClassDB::bind_method(D_METHOD("remove_from_inventory", "slot_index"), &HeroPlayer::remove_from_inventory);
    ClassDB::bind_method(D_METHOD("use_item", "slot_index"), &HeroPlayer::use_item);

    ClassDB::bind_method(D_METHOD("toggle_skill_q"), &HeroPlayer::toggle_skill_q);
    ClassDB::bind_method(D_METHOD("get_skill_q_active"), &HeroPlayer::get_skill_q_active);
    ClassDB::bind_method(D_METHOD("cast_skill_w"), &HeroPlayer::cast_skill_w);
    ClassDB::bind_method(D_METHOD("get_is_windwalking"), &HeroPlayer::get_is_windwalking);
    ClassDB::bind_method(D_METHOD("get_skill_w_cooldown"), &HeroPlayer::get_skill_w_cooldown);
    ClassDB::bind_method(D_METHOD("learn_skill", "skill_name"), &HeroPlayer::learn_skill);

    ClassDB::bind_method(D_METHOD("set_movement_target", "target"), &HeroPlayer::set_movement_target);
    ClassDB::bind_method(D_METHOD("set_attack_target", "target"), &HeroPlayer::set_attack_target);
    ClassDB::bind_method(D_METHOD("set_pickup_target", "target"), &HeroPlayer::set_pickup_target);

    // Signals
    ADD_SIGNAL(MethodInfo("inventory_changed"));
    ADD_SIGNAL(MethodInfo("xp_changed", PropertyInfo(Variant::INT, "xp"), PropertyInfo(Variant::INT, "xp_to_next_level")));
    ADD_SIGNAL(MethodInfo("skill_w_cooldown_started", PropertyInfo(Variant::FLOAT, "cooldown_time")));
    ADD_SIGNAL(MethodInfo("skills_changed"));
    ADD_SIGNAL(MethodInfo("xp_gained", PropertyInfo(Variant::INT, "amount")));
}

HeroPlayer::HeroPlayer() {
    character_name = "Archer Hero";
    level = 1;
    strength = 15;
    agility = 22;      // Primary attribute
    intelligence = 13;
    base_atk = 18.0f;
    base_def = 1.0f;
    move_speed = 175.0f;

    xp_to_next_level = 100;
    xp = 0;
    skill_points = 1; // Start with 1 skill point

    // Initialize inventory with 6 empty slots
    inventory.resize(INVENTORY_SIZE);
    for (int i = 0; i < INVENTORY_SIZE; ++i) {
        inventory[i] = Dictionary();
    }
}

HeroPlayer::~HeroPlayer() {}

void HeroPlayer::_ready() {
    if (Engine::get_singleton()->is_editor_hint()) {
        return;
    }
    
    // Add to player group
    add_to_group("player");

    // Initialize nav agent
    nav_agent = get_node<NavigationAgent2D>("NavigationAgent2D");
    if (nav_agent) {
        nav_agent->set_path_desired_distance(15.0f);
        nav_agent->set_target_desired_distance(15.0f);
    }

    // Set starting HP & MP to max
    set_hp(get_total_max_hp());
    set_mp(get_total_max_mp());
}

void HeroPlayer::_physics_process(double delta) {
    if (Engine::get_singleton()->is_editor_hint() || is_dead) {
        return;
    }

    // Cooldown management
    if (attack_cooldown > 0.0f) {
        attack_cooldown -= delta;
    }
    if (skill_w_cooldown > 0.0f) {
        skill_w_cooldown -= delta;
    }
    if (is_windwalking) {
        skill_w_duration -= delta;
        if (skill_w_duration <= 0.0f) {
            is_windwalking = false;
            set_modulate(Color(1.0f, 1.0f, 1.0f, 1.0f)); // restore transparency
        }
    }

    // Check target validity using instance ID - safe even if the object was freed.
    // is_queued_for_deletion() is NOT safe on freed memory; is_instance_id_valid() queries
    // the internal ObjectDB which is always consistent.
    if (target_node_id_ != 0 && !UtilityFunctions::is_instance_id_valid((int64_t)target_node_id_)) {
        target_node = nullptr;
        target_node_id_ = 0;
        is_attacking = false;
        is_picking_up = false;
        is_moving_to_target = false;
        set_velocity(Vector2(0, 0));
    } else if (target_node && target_node->has_method("get_is_dead") && (bool)target_node->call("get_is_dead")) {
        target_node = nullptr;
        target_node_id_ = 0;
        is_attacking = false;
        is_picking_up = false;
        is_moving_to_target = false;
        set_velocity(Vector2(0, 0));
    }

    if (is_attacking && target_node) {
        float dist = get_global_position().distance_to(target_node->get_global_position());
        if (dist <= attack_range) {
            // Stop and attack
            set_velocity(Vector2(0, 0));
            is_moving_to_target = false;
            
            if (attack_cooldown <= 0.0f) {
                // Determine if searing arrow Q is used
                bool use_searing = false;
                if (skill_q_active && skill_q_level > 0 && mp >= skill_q_mana_cost) {
                    use_searing = true;
                    set_mp(mp - skill_q_mana_cost);
                }

                shoot_projectile(target_node, use_searing);
                attack_cooldown = attack_rate;
            }
        } else {
            // Out of range, move to enemy
            is_moving_to_target = true;
            if (nav_agent) {
                nav_agent->set_target_position(target_node->get_global_position());
            }
        }
    } else if (is_picking_up && target_node) {
        float dist = get_global_position().distance_to(target_node->get_global_position());
        if (dist <= 30.0f) {
            // Pick it up
            set_velocity(Vector2(0, 0));
            is_moving_to_target = false;
            is_picking_up = false;
            
            ItemDrop *item_drop = Object::cast_to<ItemDrop>(target_node);
            if (item_drop) {
                Dictionary item_data = item_drop->get_item_data();
                if (add_to_inventory(item_data)) {
                    item_drop->queue_free();
                }
            }
            target_node = nullptr;
            target_node_id_ = 0;
        } else {
            is_moving_to_target = true;
            if (nav_agent) {
                nav_agent->set_target_position(target_node->get_global_position());
            }
        }
    }

    // Pathfinding movement execution
    if (is_moving_to_target && nav_agent) {
        if (!nav_agent->is_navigation_finished()) {
            Vector2 next_path_pos = nav_agent->get_next_path_position();
            Vector2 dir = (next_path_pos - get_global_position()).normalized();
            set_velocity(dir * get_total_move_speed());
            move_and_slide();
        } else {
            is_moving_to_target = false;
            set_velocity(Vector2(0, 0));
        }
    }

    // Visual orientation updates (Bow rotation & walk particles)
    Node2D *bow = get_node<Node2D>("Visual/Bow");
    if (bow) {
        if (target_node && is_attacking) {
            Vector2 dir = (target_node->get_global_position() - get_global_position()).normalized();
            bow->set_rotation(dir.angle());
        } else {
            Vector2 vel = get_velocity();
            if (vel.length_squared() > 10.0f) {
                bow->set_rotation(vel.angle());
            }
        }
    }
    
    Node *move_particles = get_node<Node>("MoveParticles");
    if (move_particles) {
        move_particles->set("emitting", get_velocity().length_squared() > 10.0f);
    }
}

void HeroPlayer::_unhandled_input(const Ref<InputEvent> &event) {
    if (is_dead) return;

    Ref<InputEventMouseButton> mouse_btn = event;
    if (mouse_btn.is_valid() && mouse_btn->is_pressed() && mouse_btn->get_button_index() == MOUSE_BUTTON_RIGHT) {
        Vector2 mouse_pos = get_global_mouse_position();
        
        // Setup point query parameters
        Ref<PhysicsPointQueryParameters2D> params;
        params.instantiate();
        params->set_position(mouse_pos);
        params->set_collide_with_areas(true);
        params->set_collide_with_bodies(true);

        PhysicsDirectSpaceState2D *space = get_world_2d()->get_direct_space_state();
        if (!space) return;

        TypedArray<Dictionary> intersections = space->intersect_point(params);
        Node2D *clicked_node = nullptr;
        
        for (int i = 0; i < intersections.size(); ++i) {
            Dictionary result = intersections[i];
            Node *collider = Object::cast_to<Node>(result["collider"]);
            if (collider) {
                Node2D *node2d = Object::cast_to<Node2D>(collider);
                if (node2d && (node2d->is_in_group("enemies") || node2d->is_in_group("items"))) {
                    clicked_node = node2d;
                    break;
                }
                
                Node2D *parent = Object::cast_to<Node2D>(collider->get_parent());
                if (parent && (parent->is_in_group("enemies") || parent->is_in_group("items"))) {
                    clicked_node = parent;
                    break;
                }
            }
        }

        if (clicked_node) {
            if (clicked_node->is_in_group("enemies")) {
                set_attack_target(clicked_node);
            } else if (clicked_node->is_in_group("items")) {
                set_pickup_target(clicked_node);
            }
        } else {
            set_movement_target(mouse_pos);
        }
        
        get_viewport()->set_input_as_handled();
    }
}

void HeroPlayer::set_movement_target(Vector2 target) {
    target_node = nullptr;
    target_node_id_ = 0;
    is_attacking = false;
    is_picking_up = false;
    is_moving_to_target = true;
    target_position = target;
    if (nav_agent) {
        nav_agent->set_target_position(target);
    }
}

void HeroPlayer::set_attack_target(Node2D *target) {
    target_node = target;
    target_node_id_ = target ? (uint64_t)target->get_instance_id() : 0;
    is_attacking = true;
    is_picking_up = false;
    is_moving_to_target = true;
}

void HeroPlayer::set_pickup_target(Node2D *target) {
    target_node = target;
    target_node_id_ = target ? (uint64_t)target->get_instance_id() : 0;
    is_picking_up = true;
    is_attacking = false;
    is_moving_to_target = true;
}

void HeroPlayer::shoot_projectile(Node2D *target, bool searing_shot) {
    // Face the target
    Vector2 dir = (target->get_global_position() - get_global_position()).normalized();
    
    // Spawn projectile
    Ref<PackedScene> proj_scene = ResourceLoader::get_singleton()->load("res://scenes/projectile.tscn");
    if (proj_scene.is_valid()) {
        Node *inst = proj_scene->instantiate();
        Projectile *proj = Object::cast_to<Projectile>(inst);
        if (proj) {
            proj->set_global_position(get_global_position() + dir * 15.0f);
            proj->set_target(target);
            
            // Damage calc
            float dmg = get_total_atk();
            if (searing_shot) {
                dmg += skill_q_bonus_damage * skill_q_level;
                proj->set_searing_effect(true);
            }
            
            if (is_windwalking) {
                // Break windwalk and deal bonus damage
                dmg += 30.0f * skill_w_level;
                is_windwalking = false;
                set_modulate(Color(1.0f, 1.0f, 1.0f, 1.0f));
            }
            
            proj->set_damage(dmg);
            proj->set_attacker(this);
            get_parent()->add_child(proj);
        }
    }
}

void HeroPlayer::add_xp(int p_xp) {
    if (is_dead) return;
    xp += p_xp;
    emit_signal("xp_gained", p_xp);
    while (xp >= xp_to_next_level) {
        xp -= xp_to_next_level;
        level++;
        skill_points++;
        xp_to_next_level = level * 100;
        
        // Increase stats
        strength += 2;
        agility += 3;
        intelligence += 2;
        
        // Fully restore HP & MP
        set_hp(get_total_max_hp());
        set_mp(get_total_max_mp());
        
        emit_signal("level_up", level);
    }
    emit_signal("xp_changed", xp, xp_to_next_level);
}

bool HeroPlayer::add_to_inventory(const Dictionary &item) {
    for (int i = 0; i < INVENTORY_SIZE; ++i) {
        Dictionary slot = inventory[i];
        if (slot.is_empty()) {
            inventory[i] = item.duplicate();
            recalculate_item_bonuses();
            emit_signal("inventory_changed");
            return true;
        }
    }
    UtilityFunctions::print("Inventory full!");
    return false;
}

void HeroPlayer::remove_from_inventory(int slot_index) {
    if (slot_index >= 0 && slot_index < INVENTORY_SIZE) {
        inventory[slot_index] = Dictionary();
        recalculate_item_bonuses();
        emit_signal("inventory_changed");
    }
}

void HeroPlayer::use_item(int slot_index) {
    if (slot_index < 0 || slot_index >= INVENTORY_SIZE) return;
    
    Dictionary item = inventory[slot_index];
    if (item.is_empty()) return;

    String type = item.get("type", "misc");
    if (type == "potion") {
        float hp_restore = item.get("hp_restore", 0.0f);
        float mp_restore = item.get("mp_restore", 0.0f);
        
        if (hp_restore > 0.0f) heal(hp_restore);
        if (mp_restore > 0.0f) restore_mana(mp_restore);
        
        // Consume item
        remove_from_inventory(slot_index);
    }
}

void HeroPlayer::recalculate_item_bonuses() {
    // HP, MP re-clamp triggered in character methods upon setting agility/str/intel
    // Just force update properties. Bonuses are calculated dynamically in overrides.
    set_hp(hp);
    set_mp(mp);
}

float HeroPlayer::get_total_atk() const {
    float bonus_atk = 0.0f;
    for (int i = 0; i < INVENTORY_SIZE; ++i) {
        Dictionary slot = inventory[i];
        if (!slot.is_empty()) {
            bonus_atk += (float)slot.get("atk_bonus", 0.0f);
        }
    }
    return Character::get_total_atk() + bonus_atk;
}

float HeroPlayer::get_total_def() const {
    float bonus_def = 0.0f;
    for (int i = 0; i < INVENTORY_SIZE; ++i) {
        Dictionary slot = inventory[i];
        if (!slot.is_empty()) {
            bonus_def += (float)slot.get("def_bonus", 0.0f);
        }
    }
    return Character::get_total_def() + bonus_def;
}

float HeroPlayer::get_total_move_speed() const {
    float bonus_speed = 0.0f;
    for (int i = 0; i < INVENTORY_SIZE; ++i) {
        Dictionary slot = inventory[i];
        if (!slot.is_empty()) {
            bonus_speed += (float)slot.get("speed_bonus", 0.0f);
        }
    }
    float speed = Character::get_total_move_speed() + bonus_speed;
    if (is_windwalking) {
        speed *= (1.0f + 0.10f * skill_w_level); // 10% speed boost per skill level
    }
    return speed;
}

void HeroPlayer::toggle_skill_q() {
    if (skill_q_level > 0) {
        skill_q_active = !skill_q_active;
        emit_signal("skills_changed");
    }
}

void HeroPlayer::cast_skill_w() {
    if (skill_w_level > 0 && skill_w_cooldown <= 0.0f && mp >= skill_w_mana_cost) {
        set_mp(mp - skill_w_mana_cost);
        is_windwalking = true;
        skill_w_duration = 5.0f + skill_w_level * 2.0f;
        skill_w_cooldown = skill_w_cooldown_max;
        
        // Apply translucency visual effect
        set_modulate(Color(1.0f, 1.0f, 1.0f, 0.4f));
        
        emit_signal("skill_w_cooldown_started", skill_w_cooldown_max);
        emit_signal("skills_changed");
        
        // De-aggro current enemies chasing
        // (Enemies will check get_is_windwalking() in their update loop)
    }
}

void HeroPlayer::learn_skill(const String &skill_name) {
    if (skill_points <= 0) return;
    
    if (skill_name == "Q" && skill_q_level < 4) {
        skill_q_level++;
        skill_points--;
        emit_signal("skills_changed");
    } else if (skill_name == "W" && skill_w_level < 4) {
        skill_w_level++;
        skill_points--;
        emit_signal("skills_changed");
    }
}

void HeroPlayer::die() {
    Character::die();
    set_velocity(Vector2(0, 0));
    // Let GameManager handle player death screen
}

} // namespace godot
