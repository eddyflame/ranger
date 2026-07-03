#ifndef ENEMY_H
#define ENEMY_H

#include "character.h"
#include <godot_cpp/classes/navigation_agent2d.hpp>

namespace godot {

class Enemy : public Character {
    GDCLASS(Enemy, Character)

public:
    enum State {
        STATE_IDLE,
        STATE_CHASE,
        STATE_ATTACK,
        STATE_RETURN
    };

protected:
    static void _bind_methods();

    State current_state = STATE_IDLE;
    NavigationAgent2D *nav_agent = nullptr;
    Node2D *target_node = nullptr;

    Vector2 home_position;
    float aggro_range = 150.0f;
    float attack_range = 50.0f; // Melee default
    float chase_limit = 350.0f; // Distance from home before returning

    float attack_cooldown = 0.0f;
    float attack_rate = 1.5f;

    int xp_reward = 25;
    TypedArray<Dictionary> loot_table;

public:
    Enemy();
    ~Enemy();

    void _ready() override;
    void _physics_process(double delta) override;

    void set_aggro_range(float p_range) { aggro_range = p_range; }
    float get_aggro_range() const { return aggro_range; }

    void set_attack_range(float p_range) { attack_range = p_range; }
    float get_attack_range() const { return attack_range; }

    void set_xp_reward(int p_xp) { xp_reward = p_xp; }
    int get_xp_reward() const { return xp_reward; }

    void add_loot_item(const Dictionary &item);
    
    void die() override;
    void spawn_loot();

    virtual void attack_player();
};

} // namespace godot

#endif // ENEMY_H
