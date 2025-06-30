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



func _ready():
	_update_cursor()
	# プレイヤーのステータスをUIに表示
	label_hp.text = "HP: %d" % battle_manager.player["hp"]
	label_atk.text = "攻撃: %d" % battle_manager.player["atk"]
	label_def.text = "防御: %d" % battle_manager.player["def"]
	
func _input(event):
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
	command_log_label.text  = "「%s」を選択しました" % cmd	
