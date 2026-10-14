extends StaticBody3D

signal ball_hit(hit_normal: Vector3, hit_position: Vector3)

@export var move_speed: float = 12.0
@export var width: float = 2.0

const ARENA_HALF_WIDTH: float = 5.5
const PADDLE_Z: float = 9.0
const MOUSE_SENSITIVITY: float = 0.002

@onready var _mesh: MeshInstance3D = $PaddleMesh
@onready var _sparks: GPUParticles3D = $HitSparks

func _ready() -> void:
	position.z = PADDLE_Z
	position.y = 0.3
	_update_width()

func _physics_process(delta: float) -> void:
	var input_dir := 0.0
	if Input.is_action_pressed("ui_left"):
		input_dir = -1.0
	if Input.is_action_pressed("ui_right"):
		input_dir = 1.0

	# Mouse delta contribution
	var mouse_rel := Input.get_last_mouse_velocity().x * MOUSE_SENSITIVITY
	input_dir += mouse_rel

	position.x = clamp(
		position.x + input_dir * move_speed * delta,
		-ARENA_HALF_WIDTH + width * 0.5,
		ARENA_HALF_WIDTH - width * 0.5
	)

func set_width(new_width: float) -> void:
	width = new_width
	_update_width()

func emit_hit_sparks() -> void:
	_sparks.restart()
	_sparks.emitting = true

func get_spin_from_hit(hit_x: float) -> float:
	# Returns -1..1 based on where ball hits relative to paddle center
	if width == 0.0:
		return 0.0
	return clamp((hit_x - position.x) / (width * 0.5), -1.0, 1.0)

func _update_width() -> void:
	var box_shape := BoxShape3D.new()
	box_shape.size = Vector3(width, 0.15, 0.4)
	$CollisionShape3D.shape = box_shape
	var box_mesh := _mesh.mesh as BoxMesh
	if box_mesh:
		box_mesh.size = Vector3(width, 0.15, 0.4)
	else:
		push_error("Paddle: _mesh.mesh is not a BoxMesh")
