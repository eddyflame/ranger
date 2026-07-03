#include "enemy.h"
#include "hero_player.h"
#include "item_drop.h"
#include "projectile.h"
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/scene_tree.hpp>
#include <godot_cpp/classes/resource_loader.hpp>
#include <godot_cpp/classes/packed_scene.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

namespace godot {

void Enemy::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_aggro_range", "range"), &Enemy::set_aggro_range);
    ClassDB::bind_method(D_METHOD("get_aggro_range"), &Enemy::get_aggro_range);

    ClassDB::bind_method(D_METHOD("set_attack_range", "range"), &Enemy::set_attack_range);
    ClassDB::bind_method(D_METHOD("get_attack_range"), &Enemy::get_attack_range);

    ClassDB::bind_method(D_METHOD("set_xp_reward", "xp"), &Enemy::set_xp_reward);
    ClassDB::bind_method(D_METHOD("get_xp_reward"), &Enemy::get_xp_reward);

    ClassDB::bind_method(D_METHOD("add_loot_item", "item"), &Enemy::add_loot_item);
    ClassDB::bind_method(D_METHOD("spawn_loot"), &Enemy::spawn_loot);
    
    ClassDB::bind_method(D_METHOD("set_is_ranged", "ranged"), &Enemy::set_is_ranged);
    ClassDB::bind_method(D_METHOD("get_is_ranged"), &Enemy::get_is_ranged);
    
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "aggro_range"), "set_aggro_range", "get_aggro_range");
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "attack_range"), "set_attack_range", "get_attack_range");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "xp_reward"), "set_xp_reward", "get_xp_reward");
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "is_ranged"), "set_is_ranged", "get_is_ranged");
}

Enemy::Enemy() {
    character_name = "Forest Wolf";
    level = 1;
    strength = 8;
    agility = 6;
    intelligence = 2;
    base_atk = 8.0f;
    base_def = 1.0f;
    move_speed = 110.0f;
    xp_reward = 20;
}

Enemy::~Enemy() {}

void Enemy::_ready() {
    if (Engine::get_singleton()->is_editor_hint()) {
        return;
    }

    add_to_group("enemies");
    home_position = get_global_position();

    nav_agent = get_node<NavigationAgent2D>("NavigationAgent2D");
    if (nav_agent) {
        nav_agent->set_path_desired_distance(10.0f);
        nav_agent->set_target_desired_distance(10.0f);
    }

    // Set starting HP & MP to max
    set_hp(get_total_max_hp());
    set_mp(get_total_max_mp());
}

void Enemy::_physics_process(double delta) {
    if (Engine::get_singleton()->is_editor_hint() || is_dead) {
        return;
    }

    if (attack_cooldown > 0.0f) {
        attack_cooldown -= delta;
    }

    SceneTree *tree = get_tree();
    if (!tree) return;

    // Safely re-fetch player each frame via the group registry (always consistent).
    // If player was fully freed, get_first_node_in_group returns null.
    HeroPlayer *player = Object::cast_to<HeroPlayer>(tree->get_first_node_in_group("player"));

    // If player node is gone from scene but we still hold a stale raw pointer, clear it NOW
    // before it can be dereferenced as a dangling pointer.
    if (!player && target_node) {
        target_node = nullptr;
        current_state = STATE_RETURN;
        set_velocity(Vector2(0, 0));
    }

    // De-aggro if player is alive in scene but dead/windwalking
    if (player && (player->get_is_dead() || player->get_is_windwalking())) {
        if (target_node == player) {
            target_node = nullptr;
            current_state = STATE_RETURN;
        }
    }

    switch (current_state) {
        case STATE_IDLE: {
            if (player && !player->get_is_dead() && !player->get_is_windwalking()) {
                float dist = get_global_position().distance_to(player->get_global_position());
                if (dist <= aggro_range) {
                    target_node = player;
                    current_state = STATE_CHASE;
                }
            }
            set_velocity(Vector2(0, 0));
            break;
        }
        case STATE_CHASE: {
            if (!target_node) {
                current_state = STATE_RETURN;
                break;
            }

            float dist_from_home = get_global_position().distance_to(home_position);
            if (dist_from_home > chase_limit) {
                target_node = nullptr;
                current_state = STATE_RETURN;
                break;
            }

            float dist_to_player = get_global_position().distance_to(target_node->get_global_position());
            if (dist_to_player <= attack_range) {
                current_state = STATE_ATTACK;
            } else {
                if (nav_agent) {
                    nav_agent->set_target_position(target_node->get_global_position());
                    if (!nav_agent->is_navigation_finished()) {
                        Vector2 next_pos = nav_agent->get_next_path_position();
                        Vector2 dir = (next_pos - get_global_position()).normalized();
                        set_velocity(dir * get_total_move_speed());
                        move_and_slide();
                    }
                }
            }
            break;
        }
        case STATE_ATTACK: {
            if (!target_node) {
                current_state = STATE_RETURN;
                break;
            }

            float dist = get_global_position().distance_to(target_node->get_global_position());
            if (dist > attack_range + 20.0f) {
                current_state = STATE_CHASE;
            } else {
                set_velocity(Vector2(0, 0));
                if (attack_cooldown <= 0.0f) {
                    attack_player();
                    attack_cooldown = attack_rate;
                }
            }
            break;
        }
        case STATE_RETURN: {
            float dist = get_global_position().distance_to(home_position);
            if (dist <= 15.0f) {
                current_state = STATE_IDLE;
                // Heal slowly when returned to home (War3 creep mechanic)
                heal(get_total_max_hp() * 0.2f); 
                set_velocity(Vector2(0, 0));
            } else {
                if (nav_agent) {
                    nav_agent->set_target_position(home_position);
                    if (!nav_agent->is_navigation_finished()) {
                        Vector2 next_pos = nav_agent->get_next_path_position();
                        Vector2 dir = (next_pos - get_global_position()).normalized();
                        set_velocity(dir * get_total_move_speed());
                        move_and_slide();
                    }
                }
            }
            break;
        }
    }
}

void Enemy::attack_player() {
    if (!target_node) return;
    
    if (is_ranged) {
        Ref<PackedScene> proj_scene = ResourceLoader::get_singleton()->load("res://scenes/projectile.tscn");
        if (proj_scene.is_valid()) {
            Node *inst = proj_scene->instantiate();
            Projectile *proj = Object::cast_to<Projectile>(inst);
            if (proj) {
                Vector2 dir = (target_node->get_global_position() - get_global_position()).normalized();
                proj->set_global_position(get_global_position() + dir * 15.0f);
                proj->set_target(target_node);
                proj->set_attacker(this);
                proj->set_damage(get_total_atk());
                proj->set_speed(280.0f); // Spitter shoots slightly slower than player arrow
                get_parent()->add_child(proj);
            }
        }
    } else {
        if (target_node->has_method("take_damage")) {
            float damage = get_total_atk();
            target_node->call("take_damage", damage, this);
        }
    }
}

void Enemy::add_loot_item(const Dictionary &item) {
    loot_table.append(item);
}

void Enemy::spawn_loot() {
    if (loot_table.is_empty()) return;
    
    // Choose item from loot table
    // For simplicity, spawn first item, or let there be a chance
    int idx = UtilityFunctions::randi() % loot_table.size();
    Dictionary item_data = loot_table[idx];

    Ref<PackedScene> loot_scene = ResourceLoader::get_singleton()->load("res://scenes/item_drop.tscn");
    if (loot_scene.is_valid()) {
        Node *inst = loot_scene->instantiate();
        ItemDrop *item_drop = Object::cast_to<ItemDrop>(inst);
        if (item_drop) {
            item_drop->set_global_position(get_global_position());
            item_drop->set_item_data(item_data);
            get_parent()->add_child(item_drop);
        }
    }
}

void Enemy::die() {
    Character::die();
    set_velocity(Vector2(0, 0));
    
    SceneTree *tree = get_tree();
    if (tree) {
        HeroPlayer *player = Object::cast_to<HeroPlayer>(tree->get_first_node_in_group("player"));
        if (player) {
            player->add_xp(xp_reward);
        }
    }

    spawn_loot();
    
    // Spawn gold coins!
    int min_gold = 25;
    int max_gold = 40;
    if (get_name().contains("Boss")) {
        min_gold = 100;
        max_gold = 250;
    }
    
    int gold_dropped = UtilityFunctions::randi_range(min_gold, max_gold);
    Ref<PackedScene> gold_scene = ResourceLoader::get_singleton()->load("res://scenes/item_drop.tscn");
    if (gold_scene.is_valid()) {
        Node *inst = gold_scene->instantiate();
        ItemDrop *drop = Object::cast_to<ItemDrop>(inst);
        if (drop) {
            Dictionary gold_data;
            gold_data["name"] = "+" + String::num_int64(gold_dropped) + " 金币";
            gold_data["type"] = "gold";
            gold_data["amount"] = gold_dropped;
            
            drop->set_global_position(get_global_position() + Vector2(UtilityFunctions::randf_range(-15.0f, 15.0f), UtilityFunctions::randf_range(-15.0f, 15.0f)));
            drop->set_item_data(gold_data);
            get_parent()->add_child(drop);
        }
    }
    
    // Fade out and queue free
    queue_free();
}

} // namespace godot
