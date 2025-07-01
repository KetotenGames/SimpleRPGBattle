class_name Battler

var name: String
var max_hp: int
var hp: int
var atk: int
var def: int

func _init(name: String = "", max_hp:int = 0, atk:int = 0, def:int = 0) -> void:
	self.name = name
	self.max_hp = max_hp
	self.hp = max_hp
	self.atk = atk
	self.def = def
	
func take_damage(amount: int) -> void:
	self.hp = max(self.hp - amount, 0)
	
func is_alive() -> bool:
	return self.hp > 0
