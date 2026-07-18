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
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/input_event_mouse_button.hpp>
#include <godot_cpp/classes/input_event_key.hpp>
#include <godot_cpp/classes/navigation_server2d.hpp>
#include <godot_cpp/classes/camera2d.hpp>
#include <godot_cpp/classes/cpu_particles2d.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <cmath>

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
    ClassDB::bind_method(D_METHOD("get_skill_q_level"), &HeroPlayer::get_skill_q_level);
    ClassDB::bind_method(D_METHOD("get_skill_w_level"), &HeroPlayer::get_skill_w_level);
    ClassDB::bind_method(D_METHOD("get_skill_e_level"), &HeroPlayer::get_skill_e_level);
    ClassDB::bind_method(D_METHOD("get_skill_e_cooldown"), &HeroPlayer::get_skill_e_cooldown);
    ClassDB::bind_method(D_METHOD("get_skill_r_level"), &HeroPlayer::get_skill_r_level);
    ClassDB::bind_method(D_METHOD("get_skill_r_cooldown"), &HeroPlayer::get_skill_r_cooldown);
    ClassDB::bind_method(D_METHOD("get_talent_crit_level"), &HeroPlayer::get_talent_crit_level);
    ClassDB::bind_method(D_METHOD("get_talent_evasion_level"), &HeroPlayer::get_talent_evasion_level);
    ClassDB::bind_method(D_METHOD("get_talent_lifesteal_level"), &HeroPlayer::get_talent_lifesteal_level);
    ClassDB::bind_method(D_METHOD("get_talent_speed_level"), &HeroPlayer::get_talent_speed_level);
    ClassDB::bind_method(D_METHOD("cast_skill_e", "target_pos"), &HeroPlayer::cast_skill_e);
    ClassDB::bind_method(D_METHOD("cast_skill_e_forward"), &HeroPlayer::cast_skill_e_forward);
    ClassDB::bind_method(D_METHOD("cast_skill_r", "target_pos"), &HeroPlayer::cast_skill_r);
    ClassDB::bind_method(D_METHOD("learn_skill", "skill_name"), &HeroPlayer::learn_skill);
    ClassDB::bind_method(D_METHOD("upgrade_attribute", "attr_name"), &HeroPlayer::upgrade_attribute);
    ClassDB::bind_method(D_METHOD("trigger_shake", "intensity", "duration"), &HeroPlayer::trigger_shake);
    
    ClassDB::bind_method(D_METHOD("get_gold"), &HeroPlayer::get_gold);
    ClassDB::bind_method(D_METHOD("set_gold", "gold"), &HeroPlayer::set_gold);
    ClassDB::bind_method(D_METHOD("get_lifesteal_percent"), &HeroPlayer::get_lifesteal_percent);
    ClassDB::bind_method(D_METHOD("get_total_crit_chance"), &HeroPlayer::get_total_crit_chance);
    ClassDB::bind_method(D_METHOD("get_total_evasion_chance"), &HeroPlayer::get_total_evasion_chance);
    ClassDB::bind_method(D_METHOD("get_total_block_amount"), &HeroPlayer::get_total_block_amount);
    ClassDB::bind_method(D_METHOD("get_set_count", "set_name"), &HeroPlayer::get_set_count);
    
    ClassDB::bind_method(D_METHOD("set_xp", "xp"), &HeroPlayer::set_xp);
    ClassDB::bind_method(D_METHOD("set_skill_points", "skill_points"), &HeroPlayer::set_skill_points);
    ClassDB::bind_method(D_METHOD("set_inventory", "inventory"), &HeroPlayer::set_inventory);
    ClassDB::bind_method(D_METHOD("set_skill_q_level", "level"), &HeroPlayer::set_skill_q_level);
    ClassDB::bind_method(D_METHOD("set_skill_w_level", "level"), &HeroPlayer::set_skill_w_level);
    ClassDB::bind_method(D_METHOD("set_skill_e_level", "level"), &HeroPlayer::set_skill_e_level);
    ClassDB::bind_method(D_METHOD("set_skill_r_level", "level"), &HeroPlayer::set_skill_r_level);
    ClassDB::bind_method(D_METHOD("set_talent_crit_level", "level"), &HeroPlayer::set_talent_crit_level);
    ClassDB::bind_method(D_METHOD("set_talent_evasion_level", "level"), &HeroPlayer::set_talent_evasion_level);
    ClassDB::bind_method(D_METHOD("set_talent_lifesteal_level", "level"), &HeroPlayer::set_talent_lifesteal_level);
    ClassDB::bind_method(D_METHOD("set_talent_speed_level", "level"), &HeroPlayer::set_talent_speed_level);
 
    ClassDB::bind_method(D_METHOD("set_movement_target", "target"), &HeroPlayer::set_movement_target);
    ClassDB::bind_method(D_METHOD("set_attack_target", "target"), &HeroPlayer::set_attack_target);
    ClassDB::bind_method(D_METHOD("set_pickup_target", "target"), &HeroPlayer::set_pickup_target);
    ClassDB::bind_method(D_METHOD("revive_at_start"), &HeroPlayer::revive_at_start);
    ClassDB::bind_method(D_METHOD("revive_on_spot"), &HeroPlayer::revive_on_spot);
 
    // Signals
    ADD_SIGNAL(MethodInfo("inventory_changed"));
    ADD_SIGNAL(MethodInfo("xp_changed", PropertyInfo(Variant::INT, "xp"), PropertyInfo(Variant::INT, "xp_to_next_level")));
    ADD_SIGNAL(MethodInfo("skill_w_cooldown_started", PropertyInfo(Variant::FLOAT, "cooldown_time")));
    ADD_SIGNAL(MethodInfo("skill_r_cooldown_started", PropertyInfo(Variant::FLOAT, "cooldown_time")));
    ADD_SIGNAL(MethodInfo("skills_changed"));
    ADD_SIGNAL(MethodInfo("xp_gained", PropertyInfo(Variant::INT, "amount")));
    ADD_SIGNAL(MethodInfo("shot_projectile"));
    ADD_SIGNAL(MethodInfo("gold_changed", PropertyInfo(Variant::INT, "gold")));
    ADD_SIGNAL(MethodInfo("gold_gained", PropertyInfo(Variant::INT, "amount")));
    ADD_SIGNAL(MethodInfo("blinked", PropertyInfo(Variant::VECTOR2, "from"), PropertyInfo(Variant::VECTOR2, "to")));
    ADD_SIGNAL(MethodInfo("resurrected"));
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
    gold = 0;

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
    start_position = get_global_position();
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
    if (skill_e_cooldown > 0.0f) {
        skill_e_cooldown -= delta;
    }
    if (skill_r_cooldown > 0.0f) {
        skill_r_cooldown -= delta;
    }
    if (slow_timer > 0.0f) {
        slow_timer -= delta;
    }
    if (is_windwalking) {
        skill_w_duration -= delta;
        if (skill_w_duration <= 0.0f) {
            is_windwalking = false;
        }
    }

    // Lava Guard 3-Piece Set Aura: Doom Fury
    if (get_set_count("lava") >= 3) {
        lava_aura_timer -= delta;
        if (lava_aura_timer <= 0.0f) {
            lava_aura_timer = 2.0f;
            TypedArray<Node> enemies = get_tree()->get_nodes_in_group("enemies");
            for (int i = 0; i < enemies.size(); ++i) {
                Node2D *enemy = Object::cast_to<Node2D>(enemies[i]);
                if (enemy && !enemy->is_queued_for_deletion()) {
                    bool enemy_dead = false;
                    if (enemy->has_method("get_is_dead")) {
                        enemy_dead = (bool)enemy->call("get_is_dead");
                    }
                    if (!enemy_dead && get_global_position().distance_to(enemy->get_global_position()) <= 200.0f) {
                        if (enemy->has_method("take_damage")) {
                            enemy->call("take_damage", 30.0f, this);
                        }
                    }
                }
            }
        }
    }

    // Dynamic visual modulation for status effects (windwalk transparency and web slow tint)
    Color mod_color = Color(1.0f, 1.0f, 1.0f, 1.0f);
    if (is_windwalking) {
        mod_color.a = 0.4f;
    }
    if (slow_timer > 0.0f) {
        mod_color.r = 0.7f;
        mod_color.g = 0.5f;
        mod_color.b = 0.9f;
    }
    set_modulate(mod_color);

    // Slowly regenerate mana: 1.0f + intelligence * 0.05f per second
    float mana_regen = 1.0f + intelligence * 0.05f;
    set_mp(mp + mana_regen * delta);

    // Process camera shake
    if (shake_duration > 0.0f) {
        shake_duration -= delta;
        Camera2D *cam = get_node<Camera2D>("Camera2D");
        if (cam) {
            if (shake_duration <= 0.0f) {
                cam->set_offset(Vector2(0, 0));
            } else {
                float off_x = UtilityFunctions::randf_range(-shake_intensity, shake_intensity);
                float off_y = UtilityFunctions::randf_range(-shake_intensity, shake_intensity);
                cam->set_offset(Vector2(off_x, off_y));
            }
        }
    }

    // Process MoveParticles color and count modulation under Windwalk
    CPUParticles2D *particles = get_node<CPUParticles2D>("MoveParticles");
    if (particles) {
        if (is_windwalking) {
            particles->set_color(Color(0.2f, 0.9f, 0.6f, 0.6f));
            particles->set_amount(24);
            particles->set("scale_amount_max", 7.0f);
        } else {
            particles->set_color(Color(0.28f, 0.55f, 0.22f, 0.35f));
            particles->set_amount(12);
            particles->set("scale_amount_max", 5.0f);
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
        float interact_dist = target_node->is_in_group("merchants") ? 60.0f : 30.0f;
        if (dist <= interact_dist) {
            // Pick it up / Interact
            set_velocity(Vector2(0, 0));
            is_moving_to_target = false;
            is_picking_up = false;
            
            if (target_node->is_in_group("merchants")) {
                target_node->call("open_shop", this);
            } else {
                ItemDrop *item_drop = Object::cast_to<ItemDrop>(target_node);
                if (item_drop) {
                    Dictionary item_data = item_drop->get_item_data();
                    String item_type = item_data.get("type", "");
                    if (item_type == "gold") {
                        int amount = item_data.get("amount", 0);
                        set_gold(gold + amount);
                        emit_signal("gold_gained", amount);
                        item_drop->queue_free();
                    } else {
                        if (add_to_inventory(item_data)) {
                            item_drop->queue_free();
                        }
                    }
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

    Ref<InputEventKey> key_event = event;
    if (key_event.is_valid() && key_event->is_pressed() && !key_event->is_echo()) {
        Key keycode = key_event->get_keycode();
        if (keycode == KEY_Q) {
            toggle_skill_q();
            get_viewport()->set_input_as_handled();
            return;
        } else if (keycode == KEY_W) {
            cast_skill_w();
            get_viewport()->set_input_as_handled();
            return;
        } else if (keycode == KEY_E) {
            cast_skill_e(get_global_mouse_position());
            get_viewport()->set_input_as_handled();
            return;
        } else if (keycode == KEY_R) {
            cast_skill_r(get_global_mouse_position());
            get_viewport()->set_input_as_handled();
            return;
        }
    }

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
                if (node2d && (node2d->is_in_group("enemies") || node2d->is_in_group("items") || node2d->is_in_group("merchants"))) {
                    clicked_node = node2d;
                    break;
                }
                
                Node2D *parent = Object::cast_to<Node2D>(collider->get_parent());
                if (parent && (parent->is_in_group("enemies") || parent->is_in_group("items") || parent->is_in_group("merchants"))) {
                    clicked_node = parent;
                    break;
                }
            }
        }

        if (clicked_node) {
            if (clicked_node->is_in_group("enemies")) {
                set_attack_target(clicked_node);
            } else if (clicked_node->is_in_group("items") || clicked_node->is_in_group("merchants")) {
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
            
            float crit_chance = get_total_crit_chance();
            if (crit_chance > 0.0f && UtilityFunctions::randf() < crit_chance) {
                dmg *= 2.0f;
                proj->set_meta("is_crit", true);
            }
            
            proj->set_damage(dmg);
            proj->set_attacker(this);
            get_parent()->add_child(proj);
            emit_signal("shot_projectile");
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
    float atk = Character::get_total_atk() + bonus_atk;
    if (get_set_count("champion") >= 2) {
        atk *= 1.15f;
    }
    return atk;
}

float HeroPlayer::get_total_def() const {
    float bonus_def = 0.0f;
    for (int i = 0; i < INVENTORY_SIZE; ++i) {
        Dictionary slot = inventory[i];
        if (!slot.is_empty()) {
            bonus_def += (float)slot.get("def_bonus", 0.0f);
        }
    }
    float def = Character::get_total_def() + bonus_def;
    if (get_set_count("lava") >= 2) {
        def += 10.0f;
    }
    return def;
}

float HeroPlayer::get_total_move_speed() const {
    float bonus_speed = 0.0f;
    for (int i = 0; i < INVENTORY_SIZE; ++i) {
        Dictionary slot = inventory[i];
        if (!slot.is_empty()) {
            bonus_speed += (float)slot.get("speed_bonus", 0.0f);
        }
    }
    float speed = move_speed + bonus_speed + talent_speed_level * 10.0f;
    if (is_windwalking) {
        speed *= (1.0f + 0.10f * skill_w_level); // 10% speed boost per skill level
    }
    if (slow_timer > 0.0f) {
        speed *= 0.5f;
    }
    // Cap max movement speed to prevent runaway stacking
    const float kMaxMoveSpeed = 320.0f;
    if (speed > kMaxMoveSpeed) {
        speed = kMaxMoveSpeed;
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
    } else if (skill_name == "E" && skill_e_level < 4) {
        skill_e_level++;
        skill_points--;
        emit_signal("skills_changed");
    } else if (skill_name == "R" && skill_r_level < 4) {
        skill_r_level++;
        skill_points--;
        emit_signal("skills_changed");
    } else if (skill_name == "T_CRIT" && talent_crit_level < 4) {
        talent_crit_level++;
        skill_points--;
        emit_signal("skills_changed");
    } else if (skill_name == "T_EVADE" && talent_evasion_level < 4) {
        talent_evasion_level++;
        skill_points--;
        emit_signal("skills_changed");
    } else if (skill_name == "T_LIFE" && talent_lifesteal_level < 4) {
        talent_lifesteal_level++;
        skill_points--;
        emit_signal("skills_changed");
    } else if (skill_name == "T_SPEED" && talent_speed_level < 4) {
        talent_speed_level++;
        skill_points--;
        emit_signal("skills_changed");
    }
}

void HeroPlayer::upgrade_attribute(const String &attr_name) {
    if (skill_points <= 0) return;
    
    if (attr_name == "strength") {
        strength++;
        set_hp(hp + 20.0f); // Add 20 HP from strength
    } else if (attr_name == "agility") {
        agility++;
        set_hp(hp); // Trigger recalculation/clamp
    } else if (attr_name == "intelligence") {
        intelligence++;
        set_mp(mp + 15.0f); // Add 15 MP from intelligence
    } else {
        return; // Invalid attribute name
    }
    
    skill_points--;
    emit_signal("skills_changed");
}

void HeroPlayer::cast_skill_e(Vector2 target_pos) {
    if (skill_e_level <= 0 || skill_e_cooldown > 0.0f || hp <= 0.0f) return;
    
    float mana_cost = 20.0f;
    if (mp < mana_cost) return;
    
    float max_range = 150.0f + 50.0f * skill_e_level;
    Vector2 current_pos = get_global_position();
    Vector2 diff = target_pos - current_pos;
    float dist = diff.length();
    
    if (dist > max_range) {
        target_pos = current_pos + diff.normalized() * max_range;
    }
    
    RID map = get_world_2d()->get_navigation_map();
    Vector2 walkable_pos = NavigationServer2D::get_singleton()->map_get_closest_point(map, target_pos);
    
    set_global_position(walkable_pos);
    nav_agent->set_target_position(walkable_pos);
    set_velocity(Vector2(0, 0));
    
    skill_e_cooldown = 12.0f - 2.0f * skill_e_level; // Cooldown: 10s, 8s, 6s, 4s
    set_mp(mp - mana_cost);
    
    emit_signal("skills_changed");
    emit_signal("blinked", current_pos, walkable_pos);
}

void HeroPlayer::cast_skill_e_forward() {
    Vector2 dir = Vector2(std::cos(get_rotation()), std::sin(get_rotation())).normalized();
    cast_skill_e(get_global_position() + dir * 150.0f);
}

void HeroPlayer::trigger_shake(float intensity, float duration) {
    shake_intensity = intensity;
    shake_duration = duration;
}

void HeroPlayer::set_gold(int p_gold) {
    gold = p_gold;
    emit_signal("gold_changed", gold);
}

float HeroPlayer::get_lifesteal_percent() const {
    float lifesteal = talent_lifesteal_level * 0.04f;
    for (int i = 0; i < INVENTORY_SIZE; ++i) {
        Dictionary slot = inventory[i];
        if (!slot.is_empty()) {
            lifesteal += (float)slot.get("lifesteal_percent", 0.0f);
        }
    }
    if (get_set_count("shadow") >= 3) {
        lifesteal += 0.15f;
    }
    return lifesteal;
}

float HeroPlayer::get_total_crit_chance() const {
    float total_crit = talent_crit_level * 0.05f;
    for (int i = 0; i < INVENTORY_SIZE; ++i) {
        Dictionary slot = inventory[i];
        if (!slot.is_empty()) {
            total_crit += (float)slot.get("crit_chance", 0.0f);
        }
    }
    if (get_set_count("champion") >= 3) {
        total_crit += 0.20f;
    }
    return total_crit;
}

float HeroPlayer::get_total_evasion_chance() const {
    float total_evade = talent_evasion_level * 0.05f;
    for (int i = 0; i < INVENTORY_SIZE; ++i) {
        Dictionary slot = inventory[i];
        if (!slot.is_empty()) {
            total_evade += (float)slot.get("evade_chance", 0.0f);
        }
    }
    if (get_set_count("shadow") >= 2) {
        total_evade += 0.15f;
    }
    return total_evade;
}

float HeroPlayer::get_total_block_amount() const {
    float total_block = 0.0f;
    for (int i = 0; i < INVENTORY_SIZE; ++i) {
        Dictionary slot = inventory[i];
        if (!slot.is_empty()) {
            total_block += (float)slot.get("block_amount", 0.0f);
        }
    }
    return total_block;
}

float HeroPlayer::get_total_max_hp() const {
    float bonus_hp = 0.0f;
    for (int i = 0; i < INVENTORY_SIZE; ++i) {
        Dictionary slot = inventory[i];
        if (!slot.is_empty()) {
            bonus_hp += (float)slot.get("hp_bonus", 0.0f);
        }
    }
    float hp_limit = Character::get_total_max_hp() + bonus_hp;
    if (get_set_count("lava") >= 2) {
        hp_limit += 150.0f;
    }
    return hp_limit;
}

int HeroPlayer::get_set_count(const String &set_name) const {
    int count = 0;
    Array counted_names;
    for (int i = 0; i < INVENTORY_SIZE; ++i) {
        Dictionary slot = inventory[i];
        if (!slot.is_empty()) {
            String s_name = slot.get("set_name", "");
            if (s_name == set_name) {
                String item_id = slot.get("set_item_id", "");
                if (!item_id.is_empty() && !counted_names.has(item_id)) {
                    counted_names.append(item_id);
                    count++;
                }
            }
        }
    }
    return count;
}

void HeroPlayer::die() {
    // Check if we have an Ankh of Reincarnation in our inventory
    int ankh_slot = -1;
    for (int i = 0; i < INVENTORY_SIZE; ++i) {
        Dictionary slot = inventory[i];
        if (!slot.is_empty() && (String)slot.get("type", "") == "ankh") {
            ankh_slot = i;
            break;
        }
    }

    if (ankh_slot != -1) {
        // Restore HP and MP to maximum FIRST before removing the item from inventory.
        // This ensures recalculate_item_bonuses() (called inside remove_from_inventory)
        // will check a positive HP value and not trigger die() recursively!
        hp = get_total_max_hp();
        mp = get_total_max_mp();

        remove_from_inventory(ankh_slot);
        
        emit_signal("hp_changed", 0.0f, hp, get_total_max_hp());
        emit_signal("mp_changed", 0.0f, mp, get_total_max_mp());
        emit_signal("resurrected");
        
        UtilityFunctions::print("[Resurrection] Ankh consumed. Player resurrected on spot!");
        return;
    }

    // Normal death
    Character::die();
    set_velocity(Vector2(0, 0));
}

void HeroPlayer::revive_at_start() {
    is_dead = false;
    hp = get_total_max_hp();
    mp = get_total_max_mp();
    set_global_position(start_position);
    if (nav_agent) {
        nav_agent->set_target_position(start_position);
    }
    set_velocity(Vector2(0, 0));
    is_moving_to_target = false;
    is_attacking = false;
    is_picking_up = false;
    target_node = nullptr;
    target_node_id_ = 0;
    
    emit_signal("hp_changed", 0.0f, hp, get_total_max_hp());
    emit_signal("mp_changed", 0.0f, mp, get_total_max_mp());
    emit_signal("skills_changed");
    
    UtilityFunctions::print("[Resurrection] Player revived at map start.");
}

void HeroPlayer::revive_on_spot() {
    is_dead = false;
    hp = get_total_max_hp();
    mp = get_total_max_mp();
    set_velocity(Vector2(0, 0));
    is_moving_to_target = false;
    is_attacking = false;
    is_picking_up = false;
    target_node = nullptr;
    target_node_id_ = 0;
    
    emit_signal("hp_changed", 0.0f, hp, get_total_max_hp());
    emit_signal("mp_changed", 0.0f, mp, get_total_max_mp());
    emit_signal("skills_changed");
    
    UtilityFunctions::print("[Resurrection] Player revived on spot.");
}

void HeroPlayer::set_level(int p_level) {
    Character::set_level(p_level);
    xp_to_next_level = level * 100;
    emit_signal("xp_changed", xp, xp_to_next_level);
}

void HeroPlayer::set_xp(int p_xp) {
    xp = p_xp;
    emit_signal("xp_changed", xp, xp_to_next_level);
}

void HeroPlayer::set_skill_points(int p_pts) {
    skill_points = p_pts;
    emit_signal("skills_changed");
}

void HeroPlayer::set_inventory(const Array &p_inv) {
    Array temp_inv = p_inv.duplicate();
    inventory.clear();
    inventory.resize(INVENTORY_SIZE);
    for (int i = 0; i < INVENTORY_SIZE && i < temp_inv.size(); ++i) {
        inventory[i] = temp_inv[i];
    }
    recalculate_item_bonuses();
    emit_signal("inventory_changed");
}

void HeroPlayer::set_skill_q_level(int p_lvl) {
    skill_q_level = p_lvl;
    emit_signal("skills_changed");
}

void HeroPlayer::set_skill_w_level(int p_lvl) {
    skill_w_level = p_lvl;
    emit_signal("skills_changed");
}

void HeroPlayer::set_skill_e_level(int p_lvl) {
    skill_e_level = p_lvl;
    emit_signal("skills_changed");
}

void HeroPlayer::set_skill_r_level(int p_lvl) {
    skill_r_level = p_lvl;
    emit_signal("skills_changed");
}

void HeroPlayer::cast_skill_r(Vector2 target_pos) {
    if (skill_r_level > 0 && skill_r_cooldown <= 0.0f && mp >= skill_r_mana_cost) {
        set_mp(mp - skill_r_mana_cost);
        skill_r_cooldown = skill_r_cooldown_max;

        Ref<PackedScene> rain_scene = ResourceLoader::get_singleton()->load("res://scenes/arrow_rain.tscn");
        if (rain_scene.is_valid()) {
            Node *inst = rain_scene->instantiate();
            Node2D *rain = Object::cast_to<Node2D>(inst);
            if (rain) {
                rain->set_global_position(target_pos);
                float base_damage = 8.0f + skill_r_level * 5.0f;
                float tick_damage = base_damage + get_total_atk() * 0.25f;
                rain->call("setup", tick_damage, this);
                get_parent()->add_child(rain);
            }
        }

        emit_signal("skill_r_cooldown_started", skill_r_cooldown_max);
        emit_signal("skills_changed");
    }
}

void HeroPlayer::set_talent_crit_level(int p_lvl) {
    talent_crit_level = p_lvl;
    emit_signal("skills_changed");
}

void HeroPlayer::set_talent_evasion_level(int p_lvl) {
    talent_evasion_level = p_lvl;
    emit_signal("skills_changed");
}

void HeroPlayer::set_talent_lifesteal_level(int p_lvl) {
    talent_lifesteal_level = p_lvl;
    emit_signal("skills_changed");
}

void HeroPlayer::set_talent_speed_level(int p_lvl) {
    talent_speed_level = p_lvl;
    emit_signal("skills_changed");
}

} // namespace godot
