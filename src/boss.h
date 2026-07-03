#ifndef BOSS_H
#define BOSS_H

#include "enemy.h"

namespace godot {

class Boss : public Enemy {
    GDCLASS(Boss, Enemy)

private:
    float stomp_cooldown = 5.0f;
    float stomp_range = 100.0f;
    float stomp_damage = 30.0f;
    float stomp_timer = 0.0f;

protected:
    static void _bind_methods();

public:
    Boss();
    ~Boss();

    void _ready() override;
    void _physics_process(double delta) override;

    void cast_stomp();
    void die() override;
};

} // namespace godot

#endif // BOSS_H
