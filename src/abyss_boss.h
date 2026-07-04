#ifndef ABYSS_BOSS_H
#define ABYSS_BOSS_H

#include "boss.h"

namespace godot {

class AbyssBoss : public Boss {
    GDCLASS(AbyssBoss, Boss)

private:
    int current_phase = 1;
    float teleport_cooldown = 6.0f;
    float teleport_timer = 2.0f;
    float spit_cooldown = 3.2f;
    float spit_timer = 1.0f;
    float stomp_cooldown = 5.0f;
    float stomp_timer = 2.0f;

protected:
    static void _bind_methods();

public:
    AbyssBoss();
    ~AbyssBoss();

    void _ready() override;
    void _physics_process(double delta) override;

    int get_current_phase() const { return current_phase; }
    void set_current_phase(int p_phase) { current_phase = p_phase; }

    void cast_dark_bolt(Vector2 direction);
    void teleport_away();
    void die() override;
};

} // namespace godot

#endif // ABYSS_BOSS_H
