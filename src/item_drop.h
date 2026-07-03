#ifndef ITEM_DROP_H
#define ITEM_DROP_H

#include <godot_cpp/classes/node2d.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/dictionary.hpp>

namespace godot {

class ItemDrop : public Node2D {
    GDCLASS(ItemDrop, Node2D)

private:
    Dictionary item_data;

protected:
    static void _bind_methods();

public:
    ItemDrop();
    ~ItemDrop();

    void _ready() override;

    void set_item_data(const Dictionary &p_data);
    Dictionary get_item_data() const { return item_data; }

    void update_visuals();
};

} // namespace godot

#endif // ITEM_DROP_H
