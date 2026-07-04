#ifndef SPIDER_QUEEN_H
#define SPIDER_QUEEN_H

#include "boss.h"

namespace godot {

class SpiderQueen : public Boss {
    GDCLASS(SpiderQueen, Boss)

private:
    float summon_cooldown = 8.0f;
    float summon_timer = 2.0f; // Start with a small delay before first summon
    float spit_cooldown = 4.5f;
    float spit_timer = 1.0f;   // Start with a small delay before first spit

protected:
    static void _bind_methods();

public:
    SpiderQueen();
    ~SpiderQueen();

    void _ready() override;
    void _physics_process(double delta) override;

    void summon_spiderlings();
    void spit_web();
    void die() override;
};

} // namespace godot

#endif // SPIDER_QUEEN_H
