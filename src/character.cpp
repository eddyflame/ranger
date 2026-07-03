#include "character.h"
#include <godot_cpp/variant/utility_functions.hpp>

namespace godot {

void Character::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_character_name", "name"), &Character::set_character_name);
    ClassDB::bind_method(D_METHOD("get_character_name"), &Character::get_character_name);

    ClassDB::bind_method(D_METHOD("set_level", "level"), &Character::set_level);
    ClassDB::bind_method(D_METHOD("get_level"), &Character::get_level);

    ClassDB::bind_method(D_METHOD("set_hp", "hp"), &Character::set_hp);
    ClassDB::bind_method(D_METHOD("get_hp"), &Character::get_hp);

    ClassDB::bind_method(D_METHOD("set_max_hp", "max_hp"), &Character::set_max_hp);
    ClassDB::bind_method(D_METHOD("get_max_hp"), &Character::get_max_hp);

    ClassDB::bind_method(D_METHOD("set_mp", "mp"), &Character::set_mp);
    ClassDB::bind_method(D_METHOD("get_mp"), &Character::get_mp);

    ClassDB::bind_method(D_METHOD("set_max_mp", "max_mp"), &Character::set_max_mp);
    ClassDB::bind_method(D_METHOD("get_max_mp"), &Character::get_max_mp);

    ClassDB::bind_method(D_METHOD("set_strength", "strength"), &Character::set_strength);
    ClassDB::bind_method(D_METHOD("get_strength"), &Character::get_strength);

    ClassDB::bind_method(D_METHOD("set_agility", "agility"), &Character::set_agility);
    ClassDB::bind_method(D_METHOD("get_agility"), &Character::get_agility);

    ClassDB::bind_method(D_METHOD("set_intelligence", "intelligence"), &Character::set_intelligence);
    ClassDB::bind_method(D_METHOD("get_intelligence"), &Character::get_intelligence);

    ClassDB::bind_method(D_METHOD("set_base_atk", "base_atk"), &Character::set_base_atk);
    ClassDB::bind_method(D_METHOD("get_base_atk"), &Character::get_base_atk);

    ClassDB::bind_method(D_METHOD("set_base_def", "base_def"), &Character::set_base_def);
    ClassDB::bind_method(D_METHOD("get_base_def"), &Character::get_base_def);

    ClassDB::bind_method(D_METHOD("set_move_speed", "move_speed"), &Character::set_move_speed);
    ClassDB::bind_method(D_METHOD("get_move_speed"), &Character::get_move_speed);

    ClassDB::bind_method(D_METHOD("get_total_atk"), &Character::get_total_atk);
    ClassDB::bind_method(D_METHOD("get_total_def"), &Character::get_total_def);
    ClassDB::bind_method(D_METHOD("get_total_max_hp"), &Character::get_total_max_hp);
    ClassDB::bind_method(D_METHOD("get_total_max_mp"), &Character::get_total_max_mp);
    ClassDB::bind_method(D_METHOD("get_total_move_speed"), &Character::get_total_move_speed);

    ClassDB::bind_method(D_METHOD("take_damage", "amount", "attacker"), &Character::take_damage, DEFVAL(nullptr));
    ClassDB::bind_method(D_METHOD("heal", "amount"), &Character::heal);
    ClassDB::bind_method(D_METHOD("restore_mana", "amount"), &Character::restore_mana);
    ClassDB::bind_method(D_METHOD("die"), &Character::die);
    ClassDB::bind_method(D_METHOD("get_is_dead"), &Character::get_is_dead);

    // Register properties
    ADD_PROPERTY(PropertyInfo(Variant::STRING, "character_name"), "set_character_name", "get_character_name");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "level"), "set_level", "get_level");
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "hp"), "set_hp", "get_hp");
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "max_hp"), "set_max_hp", "get_max_hp");
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "mp"), "set_mp", "get_mp");
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "max_mp"), "set_max_mp", "get_max_mp");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "strength"), "set_strength", "get_strength");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "agility"), "set_agility", "get_agility");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "intelligence"), "set_intelligence", "get_intelligence");
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "base_atk"), "set_base_atk", "get_base_atk");
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "base_def"), "set_base_def", "get_base_def");
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "move_speed"), "set_move_speed", "get_move_speed");

    // Signals
    ADD_SIGNAL(MethodInfo("hp_changed", PropertyInfo(Variant::FLOAT, "old_hp"), PropertyInfo(Variant::FLOAT, "new_hp"), PropertyInfo(Variant::FLOAT, "max_hp")));
    ADD_SIGNAL(MethodInfo("mp_changed", PropertyInfo(Variant::FLOAT, "old_mp"), PropertyInfo(Variant::FLOAT, "new_mp"), PropertyInfo(Variant::FLOAT, "max_mp")));
    ADD_SIGNAL(MethodInfo("level_up", PropertyInfo(Variant::INT, "new_level")));
    ADD_SIGNAL(MethodInfo("died"));
    ADD_SIGNAL(MethodInfo("damage_taken", PropertyInfo(Variant::FLOAT, "amount"), PropertyInfo(Variant::OBJECT, "attacker")));
    ADD_SIGNAL(MethodInfo("healed", PropertyInfo(Variant::FLOAT, "amount")));
}

Character::Character() {}

Character::~Character() {}

void Character::set_level(int p_level) {
    if (p_level < 1) p_level = 1;
    level = p_level;
}

void Character::set_hp(float p_hp) {
    float limit = get_total_max_hp();
    float old_hp = hp;
    hp = UtilityFunctions::clamp(p_hp, 0.0f, limit);
    if (old_hp != hp) {
        emit_signal("hp_changed", old_hp, hp, limit);
    }
    if (hp <= 0.0f && !is_dead) {
        die();
    }
}

void Character::set_max_hp(float p_max_hp) {
    max_hp = p_max_hp;
    set_hp(hp); // Re-clamp hp
}

void Character::set_mp(float p_mp) {
    float limit = get_total_max_mp();
    float old_mp = mp;
    mp = UtilityFunctions::clamp(p_mp, 0.0f, limit);
    if (old_mp != mp) {
        emit_signal("mp_changed", old_mp, mp, limit);
    }
}

void Character::set_max_mp(float p_max_mp) {
    max_mp = p_max_mp;
    set_mp(mp); // Re-clamp mp
}

void Character::set_strength(int p_str) {
    strength = p_str;
    set_hp(hp); // Max HP changes with STR
}

void Character::set_agility(int p_agi) {
    agility = p_agi;
}

void Character::set_intelligence(int p_intel) {
    intelligence = p_intel;
    set_mp(mp); // Max MP changes with INT
}

void Character::set_base_atk(float p_atk) {
    base_atk = p_atk;
}

void Character::set_base_def(float p_def) {
    base_def = p_def;
}

// Derived calculations
float Character::get_total_max_hp() const {
    return max_hp + strength * 20.0f;
}

float Character::get_total_max_mp() const {
    return max_mp + intelligence * 15.0f;
}

float Character::get_total_atk() const {
    return base_atk + agility * 1.0f;
}

float Character::get_total_def() const {
    return base_def + agility * 0.15f;
}

float Character::get_total_move_speed() const {
    return move_speed;
}

void Character::take_damage(float amount, Node* attacker) {
    if (is_dead) return;
    
    // War3 armor formula: reduction = (armor * 0.06) / (1 + armor * 0.06)
    // For simplicity, we use: actual = amount * (20 / (20 + total_def))
    float def = get_total_def();
    float multiplier = 1.0f;
    if (def >= 0) {
        multiplier = 20.0f / (20.0f + def);
    } else {
        // Negative armor increases damage
        multiplier = 2.0f - (20.0f / (20.0f - def));
    }
    
    float actual_damage = amount * multiplier;
    if (actual_damage < 0.0f) actual_damage = 0.0f;
    
    set_hp(hp - actual_damage);
    emit_signal("damage_taken", actual_damage, attacker);
}

void Character::heal(float amount) {
    if (is_dead) return;
    float old_hp = hp;
    set_hp(hp + amount);
    float actual_heal = hp - old_hp;
    if (actual_heal > 0.0f) {
        emit_signal("healed", actual_heal);
    }
}

void Character::restore_mana(float amount) {
    if (is_dead) return;
    set_mp(mp + amount);
}

void Character::die() {
    is_dead = true;
    emit_signal("died");
}

} // namespace godot
