# BattleScene.gd
class_name BattleScene
extends Control

@onready var battle_manager: BattleManager = $BattleManager
@onready var result_label: Label = $Panel/ResultLabel
@onready var label_hp: Label = $Panel/StatusPanel/VBoxStatus/LabelHP
@onready var label_atk: Label = $Panel/StatusPanel/VBoxStatus/LabelATK
@onready var label_def: Label = $Panel/StatusPanel/VBoxStatus/LabelDEF

var commands:Array[String] = ["こうげき", "ぼうぎょ"]
var selected_index:int = 0

@onready var command_cursor_lables: Array[Label] = [
	$Panel/CommandPanel/CenterContainer/VBoxCommand/HBoxCommand1/CommandCursor1,
	$Panel/CommandPanel/CenterContainer/VBoxCommand/HBoxCommand2/CommandCursor2
]
@onready var command_log_label: Label = $Panel/LogPanel/MarginContainer/CommandLogLabel
@onready var label_enemy_hp: Label = $Panel/EnemyPanel/CenterContainer/VBoxContainer/HBoxContainer/LabelEnemyHP

var battle_ended: bool = false

@onready var enemy_flash_rect: ColorRect = $Panel/EnemyPanel/ColorRect
@onready var se_player: AudioStreamPlayer2D = $AudioStreamPlayer2D
@export var player_attack_stream: AudioStreamMP3
@export var enemy_attack_stream: AudioStreamMP3

var shake_intensity:int = 12
var shake_time: float = 0.25

var typing_speed: float = 0.04
var input_locked: bool = false
var accept_waiting_for_release: bool = false
var is_command_running: bool = false

func _ready() -> void:
	_update_player_status()
	_update_enemy_status()
	_update_cursor()
	# プレイヤーのステータスをUIに表示
	label_hp.text = "HP: %d" % battle_manager.player["hp"]
	label_atk.text = "攻撃: %d" % battle_manager.player["atk"]
	label_def.text = "防御: %d" % battle_manager.player["def"]
	
func _input(event) -> void:
	if input_locked or accept_waiting_for_release:
		return

	if battle_ended:
		return

	if event.is_action_released("ui_down"):
		selected_index = min(selected_index + 1, commands.size() - 1)
		_update_cursor()
	elif event.is_action_released("ui_up"):
		selected_index = max(selected_index - 1, 0)
		_update_cursor()
	elif event.is_action_released("ui_accept"):
		accept_waiting_for_release = true
		_on_command_selected()

func _on_typing_message_finished() -> void:
	# タイピング終了時に呼び出す（show_typing_message関数の最後に呼ぶ）
	await _wait_for_key_release("ui_accept")
	# さらに「押下」も完全に終わってから受付解放
	await get_tree().process_frame
	accept_waiting_for_release = false

# キーが離されるまで待つユーティリティ
func _wait_for_key_release(action_name: String) -> void:
	# キーが一度「完全に離される」までループ
	while Input.is_action_pressed(action_name):
		await get_tree().process_frame

func _update_cursor() -> void:
	for i in command_cursor_lables.size():
		command_cursor_lables[i].text = "▶" if i == selected_index else "　"
		
func _on_command_selected() -> void:
	if is_command_running:
		return
	is_command_running = true
	
	var cmd = commands[selected_index]
	if cmd == "こうげき":
		battle_manager.player_defending = false
		var damage = battle_manager.calc_player_attack_damage()
		battle_manager.enemy.hp -= damage
		battle_manager.enemy.hp = max(battle_manager.enemy.hp, 0)
		_update_enemy_status()
		await show_typing_message(command_log_label, "敵に%dのダメージ！" % damage)
		await _on_typing_message_finished()
		
		enemy_damage_effect()
		
		if await _check_battle_result():
			is_command_running = false
			return
		
		await get_tree().create_timer(0.6).timeout
		await _enemy_turn()
		
	elif cmd == "ぼうぎょ":
		battle_manager.player_defending = true
		await show_typing_message(command_log_label, "防御の態勢をとった！")
		await _on_typing_message_finished()
		
		await get_tree().create_timer(0.6).timeout
		await _enemy_turn()
	
	is_command_running = false

		
# 敵ステータス更新
func _update_enemy_status() -> void:
	label_enemy_hp.text = "HP: %d" % battle_manager.enemy.hp
	
func _enemy_turn() -> void:
	var damage = battle_manager.calc_enemy_attack_damage()
	battle_manager.player.hp -= damage
	battle_manager.player.hp = max(battle_manager.player.hp, 0)
	_update_player_status()
	await show_typing_message(command_log_label, "敵のこうげき！\nプレイヤーは%dのダメージを受けた！" % damage)
	await _on_typing_message_finished()
	player_damage_effect()
	
	battle_manager.player_defending = false # 1ターンで防御解除
	await _check_battle_result()
	
func _update_player_status() -> void:
	label_hp.text = "HP: %d" % battle_manager.player.hp
	
func _check_battle_result() -> bool:
	if battle_manager.enemy.hp <= 0:
		await show_typing_message(command_log_label, "敵を倒した!\n勝利！")
		await _on_typing_message_finished()
		_end_battle()
		result_label.text = "VICTORY"
		result_label.visible = true
		return true
	elif battle_manager.player.hp <= 0:
		await show_typing_message(command_log_label, "力尽きた...\nゲームオーバー")
		await _on_typing_message_finished()
		_end_battle()
		result_label.text = "GAME OVER"
		result_label.visible = true
		return true
	return false
	
func _end_battle() -> void:
	battle_ended = true

func player_damage_effect() -> void:
	se_player.stream = enemy_attack_stream
	se_player.play()
	screen_shake()
	
func screen_shake() -> void:
	var tween = create_tween()
	var origin = position	# 初期位置
	for i in 4:
		var offset = Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		tween.tween_property(self, "position", origin + offset, shake_time / 5)
	tween.tween_property(self, "position", origin, shake_time / 5)
	

func enemy_damage_effect() -> void:
	se_player.stream = player_attack_stream
	se_player.play()	# 効果音再生
	enemy_flash_rect.visible = true
	enemy_flash_rect.modulate.a = 0.5
	var tween = create_tween()
	tween.tween_property(enemy_flash_rect, "modulate:a", 0.0, 0.3)
	tween.tween_callback(Callable(self, "_on_flash_finished"))
	
func _on_flash_finished() -> void:
	enemy_flash_rect.visible = false

func show_typing_message(target_label: Label, message: String) -> void:
	input_locked = true
	target_label.text = ""
	for ch in message:
		target_label.text += ch
		await get_tree().create_timer(typing_speed).timeout
	input_locked = false
