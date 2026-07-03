#include "item_drop.h"
#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/classes/label.hpp>
#include <godot_cpp/classes/sprite2d.hpp>

namespace godot {

void ItemDrop::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_item_data", "item_data"), &ItemDrop::set_item_data);
    ClassDB::bind_method(D_METHOD("get_item_data"), &ItemDrop::get_item_data);
    ClassDB::bind_method(D_METHOD("update_visuals"), &ItemDrop::update_visuals);
}

ItemDrop::ItemDrop() {}

ItemDrop::~ItemDrop() {}

void ItemDrop::_ready() {
    if (Engine::get_singleton()->is_editor_hint()) {
        return;
    }

    add_to_group("items");
    update_visuals();
}

void ItemDrop::set_item_data(const Dictionary &p_data) {
    item_data = p_data;
    update_visuals();
}

void ItemDrop::update_visuals() {
    if (!is_inside_tree() || Engine::get_singleton()->is_editor_hint()) {
        return;
    }

    Label *label = get_node<Label>("Label");
    if (label) {
        label->set_text(item_data.get("name", "Unknown Item"));
    }
    
    // We can also swap Sprite2D texture if an icon path is provided
}

} // namespace godot
