#ifndef CHARACTER_H
#define CHARACTER_H

#include <godot_cpp/classes/character_body2d.hpp>
#include <godot_cpp/core/class_db.hpp>

namespace godot {

class Character : public CharacterBody2D {
    GDCLASS(Character, CharacterBody2D)

protected:
    static void _bind_methods();

    String character_name = "Unit";
    int level = 1;
    float hp = 100.0f;
    float max_hp = 100.0f;
    float mp = 50.0f;
    float max_mp = 50.0f;

    // Attributes
    int strength = 10;
    int agility = 10;
    int intelligence = 10;

    // Base stats (before attribute additions)
    float base_atk = 10.0f;
    float base_def = 2.0f;
    float move_speed = 150.0f;

    bool is_dead = false;
    float slow_timer = 0.0f;

public:
    Character();
    ~Character();

    // Getters and Setters
    void set_character_name(const String &p_name) { character_name = p_name; }
    String get_character_name() const { return character_name; }

    virtual void set_level(int p_level);
    int get_level() const { return level; }

    void set_hp(float p_hp);
    float get_hp() const { return hp; }

    void set_max_hp(float p_max_hp);
    float get_max_hp() const { return max_hp; }

    void set_mp(float p_mp);
    float get_mp() const { return mp; }

    void set_max_mp(float p_max_mp);
    float get_max_mp() const { return max_mp; }

    void set_strength(int p_str);
    int get_strength() const { return strength; }

    void set_agility(int p_agi);
    int get_agility() const { return agility; }

    void set_intelligence(int p_intel);
    int get_intelligence() const { return intelligence; }

    void set_base_atk(float p_atk);
    float get_base_atk() const { return base_atk; }

    void set_base_def(float p_def);
    float get_base_def() const { return base_def; }

    void set_move_speed(float p_speed) { move_speed = p_speed; }
    float get_move_speed() const { return move_speed; }

    // Derived stats calculations
    virtual float get_total_atk() const;
    virtual float get_total_def() const;
    virtual float get_total_max_hp() const;
    virtual float get_total_max_mp() const;
    virtual float get_total_move_speed() const;

    // Gameplay methods
    virtual void take_damage(float amount, Node* attacker = nullptr);
    virtual void heal(float amount);
    virtual void restore_mana(float amount);
    virtual void die();
    
    bool get_is_dead() const { return is_dead; }

    void apply_slow(float duration);
    float get_slow_timer() const { return slow_timer; }
};

} // namespace godot

#endif // CHARACTER_H
