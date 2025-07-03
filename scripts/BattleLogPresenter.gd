# BattleLogPresenter.gd
class_name BattleLogPresenter
extends Node

@export var log_label: Label

var typing_speed: float = 0.04
var typing_in_progress: bool = false

func show_typing_message(message: String) -> void:
	log_label.text = ""
	for ch in message:
		log_label.text += ch
		await get_tree().create_timer(typing_speed).timeout
