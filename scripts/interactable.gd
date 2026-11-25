class_name Interactable
extends Node3D

@export var prompt_text: String = "Examine"

var highlight_active: bool = false


func _ready() -> void:
	add_to_group("interactable")


func get_prompt(_player: Node) -> String:
	return prompt_text


func interact(_player: Node) -> void:
	pass


func set_highlight(value: bool) -> void:
	highlight_active = value
