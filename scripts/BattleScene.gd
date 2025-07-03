# BattleScene.gd
class_name BattleScene
extends Control

@onready var battle_manager: BattleManager = $BattleManager
@onready var log_presenter: BattleLogPresenter = $BattleLogPresenter
@onready var view_model: BattleViewModel = $BattleViewModel

@onready var result_label: Label = $Panel/ResultLabel
@onready var label_hp: Label = $Panel/StatusPanel/VBoxStatus/LabelHP
@onready var label_atk: Label = $Panel/StatusPanel/VBoxStatus/LabelATK
@onready var label_def: Label = $Panel/StatusPanel/VBoxStatus/LabelDEF

@onready var command_cursor_labels: Array[Label] = [
	$Panel/CommandPanel/CenterContainer/VBoxCommand/HBoxCommand1/CommandCursor1,
	$Panel/CommandPanel/CenterContainer/VBoxCommand/HBoxCommand2/CommandCursor2
]
@onready var command_log_label: Label = $Panel/LogPanel/MarginContainer/CommandLogLabel
@onready var label_enemy_hp: Label = $Panel/EnemyPanel/CenterContainer/VBoxContainer/HBoxContainer/LabelEnemyHP

@onready var enemy_flash_rect: ColorRect = $Panel/EnemyPanel/ColorRect
@onready var se_player: AudioStreamPlayer2D = $AudioStreamPlayer2D
@export var player_attack_stream: AudioStreamMP3
@export var enemy_attack_stream: AudioStreamMP3

var shake_intensity:int = 12
var shake_time: float = 0.25

var typing_speed: float = 0.04
var input_locked: bool = false

func _ready() -> void:
	_update_player_status()
	_update_enemy_status()
	_update_cursor()
	# プレイヤーのステータスをUIに表示
	label_hp.text = "HP: %d" % battle_manager.player["hp"]
	label_atk.text = "攻撃: %d" % battle_manager.player["atk"]
	label_def.text = "防御: %d" % battle_manager.player["def"]
	
func _input(event) -> void:
	if input_locked or view_model.is_command_running:
		return

	if view_model.battle_ended:
		return

	if event.is_action_released("ui_down"):
		view_model.selected_index = min(view_model.selected_index + 1, view_model.commands.size() - 1)
		_update_cursor()
	elif event.is_action_released("ui_up"):
		view_model.selected_index = max(view_model.selected_index - 1, 0)
		_update_cursor()
	elif event.is_action_released("ui_accept"):
		_on_command_selected()

func _update_cursor() -> void:
	for i in command_cursor_labels.size():
		command_cursor_labels[i].text = "▶" if i == view_model.selected_index else "　"
		
func _on_command_selected() -> void:
	if view_model.is_command_running:
		return
	view_model.is_command_running = true
	
	var cmd = view_model.commands[view_model.selected_index]
	if cmd == "こうげき":
		battle_manager.player_defending = false
		var damage = battle_manager.calc_player_attack_damage()
		battle_manager.enemy.hp -= damage
		battle_manager.enemy.hp = max(battle_manager.enemy.hp, 0)
		_update_enemy_status()
		await log_presenter.show_typing_message("敵に%dのダメージ！" % damage)
		enemy_damage_effect()
		
		if await _check_battle_result():
			view_model.is_command_running = false
			return
		
		await get_tree().create_timer(0.6).timeout
		await _enemy_turn()
		
	elif cmd == "ぼうぎょ":
		battle_manager.player_defending = true
		await log_presenter.show_typing_message("防御の態勢をとった！")
		await get_tree().create_timer(0.6).timeout
		await _enemy_turn()
	
	view_model.is_command_running = false

		
# 敵ステータス更新
func _update_enemy_status() -> void:
	view_model.update_enemy_status(
		battle_manager.enemy.hp,
		battle_manager.enemy.atk,
		battle_manager.enemy.def
	)
	label_enemy_hp.text = "HP: %d" % view_model.enemy_hp
	
func _enemy_turn() -> void:
	var damage = battle_manager.calc_enemy_attack_damage()
	battle_manager.player.hp -= damage
	battle_manager.player.hp = max(battle_manager.player.hp, 0)
	_update_player_status()
	await log_presenter.show_typing_message("敵のこうげき！\nプレイヤーは%dのダメージを受けた！" % damage)
	player_damage_effect()
	
	battle_manager.player_defending = false # 1ターンで防御解除
	await _check_battle_result()
	print("_enemy_turn end")
	
func _update_player_status() -> void:
	view_model.update_player_status(
		battle_manager.player.hp,
		battle_manager.player.atk,
		battle_manager.player.def,
	)
	label_hp.text = "HP: %d" % view_model.player_hp
	label_atk.text = "攻撃: %d" % view_model.player_atk
	label_def.text = "防御: %d" % view_model.player_def
	
func _check_battle_result() -> bool:
	if battle_manager.enemy.hp <= 0:
		print("勝利分岐へ")
		await log_presenter.show_typing_message("敵を倒した!\n勝利！")
		_end_battle()
		view_model.set_result_text("VICTORY")
		result_label.text = view_model.result_text
		result_label.visible = true
		return true
	elif battle_manager.player.hp <= 0:
		print("敗北分岐へ")
		await log_presenter.show_typing_message("力尽きた...\nゲームオーバー")
		_end_battle()
		view_model.set_result_text("GAME OVER")
		result_label.text = view_model.result_text
		result_label.visible = true
		return true
	print("バトル継続")
	return false
	
func _end_battle() -> void:
	view_model.battle_ended = true

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
	print("enemy_damage_effect called")  # 追加
	se_player.stream = player_attack_stream
	se_player.play()	# 効果音再生
	enemy_flash_rect.visible = true
	enemy_flash_rect.modulate.a = 0.5
	var tween = create_tween()
	tween.tween_property(enemy_flash_rect, "modulate:a", 0.0, 0.3)
	tween.tween_callback(Callable(self, "_on_flash_finished"))
	
func _on_flash_finished() -> void:
	enemy_flash_rect.visible = false
