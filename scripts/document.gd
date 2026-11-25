extends Interactable

var doc_id: String = ""
var _paper: StandardMaterial3D
var _ink: StandardMaterial3D
var _mark: StandardMaterial3D
var _visual: Node3D


func setup(id: String) -> void:
	doc_id = id


func _ready() -> void:
	super._ready()
	_paper = StandardMaterial3D.new()
	_paper.albedo_color = Color("c9c5ae")
	_paper.roughness = 0.92
	_ink = StandardMaterial3D.new()
	_ink.albedo_color = Color("2a2c25")
	_ink.roughness = 1.0
	_mark = StandardMaterial3D.new()
	_mark.albedo_color = Color("80352d")
	_mark.emission_enabled = true
	_mark.emission = Color("a44639")
	_mark.emission_energy_multiplier = 1.0
	_visual = Node3D.new()
	add_child(_visual)
	_build_paper()


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, rot_y: float = 0.0) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var inst := MeshInstance3D.new()
	inst.mesh = mesh
	inst.material_override = mat
	inst.position = pos
	inst.rotation.y = rot_y
	inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(inst)
	return inst


func _build_paper() -> void:
	_visual.rotation.x = -0.08
	_box(_visual, Vector3(0.36, 0.007, 0.48), Vector3(0, 0.012, 0), _paper, 0.1)
	_box(_visual, Vector3(0.38, 0.004, 0.5), Vector3(0, 0.004, -0.02), _paper, 0.08)
	for i in range(6):
		_box(_visual, Vector3(0.23 - (0.03 if i % 3 == 2 else 0.0), 0.0015, 0.009),
			Vector3(-0.03, 0.019, -0.13 + i * 0.048), _ink, 0.1)
	_box(_visual, Vector3(0.025, 0.002, 0.22), Vector3(0.24, 0.02, -0.02), _mark, 0.08)
	_box(_visual, Vector3(0.12, 0.005, 0.018), Vector3(0.06, 0.023, 0.22), _mark, 0.1)


func get_prompt(_player: Node) -> String:
	var title := str(StoryData.DOCS.get(doc_id, {}).get("title", "document"))
	return "Read — " + title


func interact(player: Node) -> void:
	player.play_interaction_animation()
	AudioManager.play_sfx("page", -12.0, 0.02)
	player.game.read_document(doc_id)


func set_highlight(value: bool) -> void:
	super.set_highlight(value)
	_visual.scale = Vector3.ONE * (1.04 if value else 1.0)
