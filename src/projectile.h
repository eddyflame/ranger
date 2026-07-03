#ifndef PROJECTILE_H
#define PROJECTILE_H

#include <godot_cpp/classes/node2d.hpp>
#include <godot_cpp/core/class_db.hpp>

namespace godot {

class Projectile : public Node2D {
    GDCLASS(Projectile, Node2D)

private:
    Node2D *target = nullptr;
    uint64_t target_id = 0;
    Node *attacker = nullptr;
    uint64_t attacker_id = 0;
    
    float speed = 350.0f;
    float damage = 10.0f;
    bool is_searing = false;
    
    Vector2 last_direction;

protected:
    static void _bind_methods();

public:
    Projectile();
    ~Projectile();

    void _ready() override;
    void _physics_process(double delta) override;

    void set_target(Node2D *p_target) {
        target = p_target;
        target_id = p_target ? (uint64_t)p_target->get_instance_id() : 0;
    }
    Node2D *get_target() const { return target; }

    void set_attacker(Node *p_attacker) {
        attacker = p_attacker;
        attacker_id = p_attacker ? (uint64_t)p_attacker->get_instance_id() : 0;
    }
    Node *get_attacker() const { return attacker; }

    void set_speed(float p_speed) { speed = p_speed; }
    float get_speed() const { return speed; }

    void set_damage(float p_damage) { damage = p_damage; }
    float get_damage() const { return damage; }

    void set_searing_effect(bool p_searing);
    bool get_searing_effect() const { return is_searing; }
};

} // namespace godot

#endif // PROJECTILE_H
