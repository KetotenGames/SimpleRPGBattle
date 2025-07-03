# Battler.gd
class_name Battler
extends Resource

@export var name: String
@export var max_hp: int
@export var atk: int
@export var def: int

var hp: int

func _init() -> void:
	self.hp = max_hp
	
func take_damage(amount: int) -> void:
	self.hp = max(self.hp - amount, 0)
	
func is_alive() -> bool:
	return self.hp > 0
	
func reset_hp() -> void:
	hp = max_hp
