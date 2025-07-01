class_name BattleManager
extends Node

var player_defending = false  # プレイヤーが防御中かどうか

var player: Battler
var enemy: Battler

func _ready() -> void:
	player = Battler.new("勇者", 100, 20, 5)
	enemy = Battler.new("敵騎士", 80, 15, 3)

# ダメージ計算
func calc_player_attack_damage() -> int:
	var dmg = player.atk - enemy.def
	return max(dmg, 1)
	
func calc_enemy_attack_damage() -> int:
	var dmg = enemy.atk - player.def
	if player_defending:
		dmg = int(floor(dmg/2))
	return max(dmg, 1)
