#ifndef HERO_PLAYER_H
#define HERO_PLAYER_H

#include "character.h"
#include <godot_cpp/classes/navigation_agent2d.hpp>
#include <godot_cpp/classes/input_event.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>

namespace godot {

class HeroPlayer : public Character {
    GDCLASS(HeroPlayer, Character)

private:
    NavigationAgent2D *nav_agent = nullptr;
    
    // Target tracking
    Node2D *target_node = nullptr; // Can be Enemy or ItemDrop
    uint64_t target_node_id_ = 0;  // instance-ID copy for safe freed-object detection
    Vector2 target_position;
    bool is_moving_to_target = false;
    bool is_attacking = false;
    bool is_picking_up = false;

    // Combat timers & stats
    float attack_cooldown = 0.0f;
    float attack_rate = 1.2f; // seconds between attacks
    float attack_range = 180.0f;

    // RPG Progression
    int xp = 0;
    int xp_to_next_level = 100;
    int skill_points = 0;

    // Inventory: 6 slots
    Array inventory;
    static const int INVENTORY_SIZE = 6;

    // Skill states
    bool skill_q_active = false; // Searing Arrows (Toggle)
    int skill_q_level = 0;
    float skill_q_mana_cost = 8.0f;
    float skill_q_bonus_damage = 15.0f;

    float skill_w_cooldown = 0.0f; // Windwalk
    float skill_w_cooldown_max = 12.0f;
    int skill_w_level = 0;
    float skill_w_duration = 0.0f;
    float skill_w_mana_cost = 40.0f;
    bool is_windwalking = false;

protected:
    static void _bind_methods();

public:
    HeroPlayer();
    ~HeroPlayer();

    void _ready() override;
    void _physics_process(double delta) override;
    void _unhandled_input(const Ref<InputEvent> &event) override;

    // XP & Leveling
    void add_xp(int p_xp);
    int get_xp() const { return xp; }
    int get_xp_to_next_level() const { return xp_to_next_level; }
    int get_skill_points() const { return skill_points; }

    // Inventory methods
    Array get_inventory() const { return inventory; }
    bool add_to_inventory(const Dictionary &item);
    void remove_from_inventory(int slot_index);
    void use_item(int slot_index);
    void recalculate_item_bonuses();

    // Skills
    void toggle_skill_q();
    bool get_skill_q_active() const { return skill_q_active; }
    void cast_skill_w();
    bool get_is_windwalking() const { return is_windwalking; }
    float get_skill_w_cooldown() const { return skill_w_cooldown; }
    
    void learn_skill(const String &skill_name);
    
    // Override stats calculations to include inventory/skill buffs
    float get_total_atk() const override;
    float get_total_def() const override;
    float get_total_move_speed() const override;

    void die() override;
    
    // Target setters
    void set_movement_target(Vector2 target);
    void set_attack_target(Node2D *target);
    void set_pickup_target(Node2D *target);

    // Helpers
    void shoot_projectile(Node2D *target, bool searing_shot);
};

} // namespace godot

#endif // HERO_PLAYER_H
