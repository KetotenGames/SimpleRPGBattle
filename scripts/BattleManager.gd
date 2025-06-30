extends Node

var player = {
	"hp": 100,
	"atk": 20,
	"def": 5
}

var enemy = {
	"hp": 80,
	"atk": 15,
	"def": 3
}

# ダメージ計算
func calc_player_attack_damage() -> int:
	var dmg = player["atk"] - enemy["def"]
	return max(dmg, 1)
	
func calc_enemy_attack_damage() -> int:
	var dmg = enemy["atk"] - player["def"]
	return max(dmg, 1)
