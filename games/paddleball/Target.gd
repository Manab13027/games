extends Area3D

signal destroyed(points: int)

enum PointValue { LOW = 100, MED = 300, HIGH = 500 }

@export var point_value: int = PointValue.LOW
@export var moves: bool = false
@export var move_speed: float = 1.5
@export var move_range: float = 1.5

@onready var _mesh: MeshInstance3D = $TargetMesh
@onready var _light: OmniLight3D = $TargetLight
@onready var _destroy_fx: GPUParticles3D = $DestroyEffect
@onready var _collision: CollisionShape3D = $CollisionShape3D

var _origin: Vector3
var _time: float = 0.0
var _destroyed: bool = false

func _ready() -> void:
	_origin = position
	body_entered.connect(_on_body_entered)
	_apply_color()

func setup(value: int, should_move: bool) -> void:
	point_value = value
	moves = should_move
	_apply_color()

func _process(delta: float) -> void:
	if not moves:
		return
	_time += delta
	position.x = _origin.x + sin(_time * move_speed) * move_range

func _apply_color() -> void:
	var mat := StandardMaterial3D.new()
	mat.emission_enabled = true
	match point_value:
		PointValue.LOW:
			mat.albedo_color = Color(0.2, 0.4, 1.0)
			mat.emission = Color(0.2, 0.4, 1.0)
			_light.light_color = Color(0.2, 0.4, 1.0)
		PointValue.MED:
			mat.albedo_color = Color(1.0, 0.5, 0.1)
			mat.emission = Color(1.0, 0.5, 0.1)
			_light.light_color = Color(1.0, 0.5, 0.1)
		PointValue.HIGH:
			mat.albedo_color = Color(1.0, 0.2, 0.2)
			mat.emission = Color(1.0, 0.2, 0.2)
			_light.light_color = Color(1.0, 0.2, 0.2)
		_:
			push_warning("Target._apply_color: unhandled point_value %d" % point_value)
	mat.emission_energy_multiplier = 2.0
	_mesh.material_override = mat

func _on_body_entered(body: Node) -> void:
	if _destroyed:
		return
	if not body.is_in_group("ball"):
		return
	_destroyed = true
	_destroy_fx.restart()
	_destroy_fx.emitting = true
	destroyed.emit(point_value)
	_mesh.visible = false
	_collision.disabled = true
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(self):
		queue_free()
