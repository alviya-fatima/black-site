extends Interactable


func _ready() -> void:
	super._ready()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("b4a980")
	mat.emission_enabled = true
	mat.emission = Color("c2b182")
	mat.emission_energy_multiplier = 0.6
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.55, 0.3, 0.03)
	var sign_inst := MeshInstance3D.new()
	sign_inst.mesh = mesh
	sign_inst.material_override = mat
	sign_inst.position = Vector3(0, 1.75, 0)
	add_child(sign_inst)
	var label := Label3D.new()
	label.text = "UP"
	label.font_size = 44
	label.pixel_size = 0.0025
	label.modulate = Color("2b2a24")
	label.position = Vector3(0, 1.75, 0.02)
	add_child(label)
	var light := OmniLight3D.new()
	light.light_color = Color("d8c99b")
	light.light_energy = 0.35
	light.omni_range = 2.2
	light.position = Vector3(0, 1.8, 0.3)
	light.shadow_enabled = false
	add_child(light)


func get_prompt(_player: Node) -> String:
	return "Climb back to the asylum"


func interact(player: Node) -> void:
	player.play_interaction_animation()
	player.game.exit_basement()
