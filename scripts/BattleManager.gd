# BattleManager.gd
class_name BattleManager
extends Node

var player_defending = false  # プレイヤーが防御中かどうか

@export var player_data: Battler
@export var enemy_data: Battler

var player: Battler
var enemy: Battler

func _ready() -> void:
	player = player_data.duplicate()
	enemy = enemy_data.duplicate()
	player.reset_hp()
	enemy.reset_hp()

# ダメージ計算
func calc_player_attack_damage() -> int:
	var dmg = player.atk - enemy.def
	return max(dmg, 1)
	
func calc_enemy_attack_damage() -> int:
	var dmg = enemy.atk - player.def
	if player_defending:
		dmg = int(floor(dmg/2))
	return max(dmg, 1)
