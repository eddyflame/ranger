#ifndef GAME_MANAGER_H
#define GAME_MANAGER_H

#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/core/class_db.hpp>

namespace godot {

class GameManager : public Node {
    GDCLASS(GameManager, Node)

private:
    static GameManager *singleton;
    bool is_victory = false;
    bool is_gameover = false;

protected:
    static void _bind_methods();

public:
    GameManager();
    ~GameManager();

    static GameManager *get_singleton() { return singleton; }

    void _ready() override;
    void _exit_tree() override;

    void trigger_victory();
    void trigger_game_over();
    
    bool get_is_victory() const { return is_victory; }
    bool get_is_gameover() const { return is_gameover; }

    void restart_game();
};

} // namespace godot

#endif // GAME_MANAGER_H
