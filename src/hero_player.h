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

    // Inventory: 8 slots
    Array inventory;
    static const int INVENTORY_SIZE = 8;

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

    float skill_e_cooldown = 0.0f; // Blink
    int skill_e_level = 0;
    
    float skill_r_cooldown = 0.0f; // Arrow Rain
    float skill_r_cooldown_max = 25.0f;
    int skill_r_level = 0;
    float skill_r_mana_cost = 75.0f;
    
    int talent_crit_level = 0;
    int talent_evasion_level = 0;
    int talent_lifesteal_level = 0;
    int talent_speed_level = 0;
    float lava_aura_timer = 2.0f;
    
    int gold = 0;
    
    float shake_intensity = 0.0f;
    float shake_duration = 0.0f;
    Vector2 start_position;

protected:
    static void _bind_methods();

public:
    HeroPlayer();
    ~HeroPlayer();

    void _ready() override;
    void _physics_process(double delta) override;
    void _unhandled_input(const Ref<InputEvent> &event) override;

    // XP & Leveling
    void set_level(int p_level) override;
    void add_xp(int p_xp);
    int get_xp() const { return xp; }
    void set_xp(int p_xp);
    int get_xp_to_next_level() const { return xp_to_next_level; }
    int get_skill_points() const { return skill_points; }
    void set_skill_points(int p_pts);
    int get_gold() const { return gold; }
    void set_gold(int p_gold);

    // Inventory methods
    Array get_inventory() const { return inventory; }
    void set_inventory(const Array &p_inv);
    bool add_to_inventory(const Dictionary &item);
    void remove_from_inventory(int slot_index);
    void use_item(int slot_index);
    void recalculate_item_bonuses();
    int get_set_count(const String &set_name) const;

    // Skills
    void toggle_skill_q();
    bool get_skill_q_active() const { return skill_q_active; }
    void cast_skill_w();
    bool get_is_windwalking() const { return is_windwalking; }
    float get_skill_w_cooldown() const { return skill_w_cooldown; }
    int get_skill_q_level() const { return skill_q_level; }
    void set_skill_q_level(int p_lvl);
    int get_skill_w_level() const { return skill_w_level; }
    void set_skill_w_level(int p_lvl);
    int get_skill_e_level() const { return skill_e_level; }
    void set_skill_e_level(int p_lvl);
    float get_skill_e_cooldown() const { return skill_e_cooldown; }
    
    int get_skill_r_level() const { return skill_r_level; }
    void set_skill_r_level(int p_lvl);
    float get_skill_r_cooldown() const { return skill_r_cooldown; }
    
    int get_talent_crit_level() const { return talent_crit_level; }
    void set_talent_crit_level(int p_lvl);
    int get_talent_evasion_level() const { return talent_evasion_level; }
    void set_talent_evasion_level(int p_lvl);
    int get_talent_lifesteal_level() const { return talent_lifesteal_level; }
    void set_talent_lifesteal_level(int p_lvl);
    int get_talent_speed_level() const { return talent_speed_level; }
    void set_talent_speed_level(int p_lvl);
    
    void cast_skill_e(Vector2 target_pos);
    void cast_skill_e_forward();
    void cast_skill_r(Vector2 target_pos);
    void trigger_shake(float intensity, float duration);
    
    void learn_skill(const String &skill_name);
    void upgrade_attribute(const String &attr_name);
    float get_lifesteal_percent() const;
    float get_total_crit_chance() const;
    float get_total_evasion_chance() const;
    float get_total_block_amount() const;
    
    // Override stats calculations to include inventory/skill buffs
    float get_total_atk() const override;
    float get_total_max_hp() const override;
    float get_total_def() const override;
    float get_total_move_speed() const override;

    void die() override;
    void revive_at_start();
    void revive_on_spot();
    
    // Target setters
    void set_movement_target(Vector2 target);
    void set_attack_target(Node2D *target);
    void set_pickup_target(Node2D *target);

    // Helpers
    void shoot_projectile(Node2D *target, bool searing_shot);
};

} // namespace godot

#endif // HERO_PLAYER_H
