extends Control

@onready var battle_manager = $BattleManager
@onready var label_hp = $Panel/StatusPanel/VBoxStatus/LabelHP
@onready var label_atk = $Panel/StatusPanel/VBoxStatus/LabelATK
@onready var label_def = $Panel/StatusPanel/VBoxStatus/LabelDEF

var commands = ["こうげき", "ぼうぎょ"]
var selected_index = 0

@onready var command_cursor_lables = [
	$Panel/CommandPanel/CenterContainer/VBoxCommand/HBoxCommand1/CommandCursor1,
	$Panel/CommandPanel/CenterContainer/VBoxCommand/HBoxCommand2/CommandCursor2
]
@onready var command_log_label = $Panel/LogPanel/MarginContainer/CommandLogLabel
@onready var label_enemy_hp = $Panel/CenterContainer/VBoxContainer/LabelEnemyHP

var battle_ended = false

func _ready():
	_update_player_status()
	_update_enemy_status()
	_update_cursor()
	# プレイヤーのステータスをUIに表示
	label_hp.text = "HP: %d" % battle_manager.player["hp"]
	label_atk.text = "攻撃: %d" % battle_manager.player["atk"]
	label_def.text = "防御: %d" % battle_manager.player["def"]
	
func _input(event):
	if battle_ended:
		return # バトル終了後は操作入力を受けつけない
		
	if event.is_action_pressed("ui_down"):
		selected_index = min(selected_index + 1, commands.size() - 1)
		_update_cursor()
	elif event.is_action_pressed("ui_up"):
		selected_index = max(selected_index - 1, 0)
		_update_cursor()
	elif event.is_action_pressed("ui_accept"):
		_on_command_selected()

func _update_cursor():
	for i in command_cursor_lables.size():
		command_cursor_lables[i].text = "▶" if i == selected_index else "　"
		
func _on_command_selected():
	var cmd = commands[selected_index]
	if cmd == "こうげき":
		var damage = battle_manager.calc_player_attack_damage()
		battle_manager.enemy["hp"] -= damage
		battle_manager.enemy["hp"] = max(battle_manager.enemy["hp"], 0)
		_update_enemy_status()
		command_log_label.text = "敵に%dのダメージ！" % damage
		
		if _check_battle_result():
			return # 勝利なら敵ターンに進まない
		
		# --- 敵の反撃ターン ---
		await get_tree().create_timer(0.6).timeout
		_enemy_turn()
		
	elif cmd == "ぼうぎょ":
		command_log_label.text = "防御の態勢をとった！"
		
# 敵ステータス更新
func _update_enemy_status():
	label_enemy_hp.text = "HP: %d" % battle_manager.enemy["hp"]
	
func _enemy_turn():
	var damage = battle_manager.calc_enemy_attack_damage()
	battle_manager.player["hp"] -= damage
	battle_manager.player["hp"] = max(battle_manager.player["hp"], 0)
	_update_player_status()
	command_log_label.text = "敵のこうげき！\nプレイヤーは%dのダメージを受けた！" % damage
	
	_check_battle_result()
	
func _update_player_status():
	label_hp.text = "HP: %d" % battle_manager.player["hp"]
	
func _check_battle_result():
	if battle_manager.enemy["hp"] <= 0:
		command_log_label.text = "敵を倒した!\n勝利！"
		_end_battle()
		return true
	elif battle_manager.player["hp"] <= 0:
		command_log_label.text = "力尽きた...\nゲームオーバー"
		_end_battle()
		return true
	return false
	
func _end_battle():
	battle_ended = true
