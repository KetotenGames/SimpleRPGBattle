# BattleViewModel.gd
class_name BattleViewModel
extends Node

## コマンド関連
# コマンド名リスト
var commands:Array[String] = ["こうげき", "ぼうぎょ"]
# 選択中のコマンドインデックス
var selected_index:int = 0

## プレイヤー
var player_hp: int = 0
var player_atk: int = 0
var player_def: int = 0

##敵
var enemy_hp: int = 0
var enemy_atk: int = 0
var enemy_def: int = 0

## 状態フラグ
var is_command_running: bool = false
var battle_ended: bool = false

## 結果ラベル（VICTORY/GAME OVERなど）
var result_text: String = ""

## シグナル
# 状態更新同期用
signal updated

func update_player_status(hp: int, atk: int, def: int) -> void:
	player_hp = hp
	player_atk = atk
	player_def = def
	emit_signal("updated")
	
func update_enemy_status(hp: int, atk: int, def: int) -> void:
	enemy_hp = hp
	enemy_atk = atk
	enemy_def = def
	emit_signal("updated")
	
func set_result_text(text: String) -> void:
	result_text = text
	emit_signal("updated")
