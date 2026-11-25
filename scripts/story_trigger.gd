extends Interactable

var trigger_text: String = "Step through"
var ending_id: int = 0
var required_flag: String = ""
var denied_text: String = "Something holds you back."
var _visual: Node3D


func setup(config: Dictionary) -> void:
	trigger_text = str(config.get("text", "Step through"))
	ending_id = int(config.get("ending_id", 0))
	required_flag = str(config.get("required_flag", ""))
	denied_text = str(config.get("denied_text", "Something holds you back."))


func _ready() -> void:
	super._ready()
	_visual = Node3D.new()
	add_child(_visual)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("b9ad8b")
	mat.emission_enabled = true
	mat.emission = Color("d4bc86")
	mat.emission_energy_multiplier = 0.9
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.8, 0.65, 0.03)
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = mat
	inst.position = Vector3(0, 0.55, 0.35)
	_visual.add_child(inst)
	var light := OmniLight3D.new()
	light.light_color = Color("d7c08c")
	light.light_energy = 0.5
	light.omni_range = 2.4
	light.position = Vector3(0, 0.7, 0.7)
	light.shadow_enabled = false
	_visual.add_child(light)


func get_prompt(_player: Node) -> String:
	return trigger_text


func interact(player: Node) -> void:
	if not required_flag.is_empty() and not GameState.has_flag(required_flag):
		AudioManager.play_sfx("door_locked", -12.0, 0.02)
		player.game.toast(denied_text)
		return
	if ending_id > 0:
		player.play_interaction_animation()
		player.game.begin_ending(ending_id)
