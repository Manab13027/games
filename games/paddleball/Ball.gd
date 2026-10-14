extends RigidBody3D

signal hit_paddle(hit_position: Vector3)
signal hit_wall
signal fell_out

@export var base_speed: float = 10.0
@export var speed_increment: float = 0.3

const MAX_SPEED: float = 40.0
const DEATH_Z: float = 11.0

@onready var _trail: GPUParticles3D = $Trail
@onready var _sparks: GPUParticles3D = $ImpactSparks
@onready var _light: OmniLight3D = $BallLight

var _current_speed: float = 0.0
var _dead: bool = false

func _ready() -> void:
	gravity_scale = 0.0
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)

func launch(speed: float) -> void:
	_dead = false
	_current_speed = speed
	linear_velocity = Vector3(0.3, 0.5, -1.0).normalized() * _current_speed

func apply_spin(spin: float) -> void:
	var vel := linear_velocity
	vel.x += spin * 3.0
	if vel.length() > 0.1:
		linear_velocity = vel.normalized() * _current_speed

func accelerate() -> void:
	_current_speed = minf(_current_speed + speed_increment, MAX_SPEED)
	if linear_velocity.length() > 0.1:
		linear_velocity = linear_velocity.normalized() * _current_speed
	_update_trail_speed()

func get_speed() -> float:
	return _current_speed

func _physics_process(_delta: float) -> void:
	if not _dead and position.z > DEATH_Z:
		_dead = true
		fell_out.emit()

	# Keep speed constant (physics may drift)
	if linear_velocity.length() > 0.1:
		linear_velocity = linear_velocity.normalized() * _current_speed

func _on_body_entered(body: Node) -> void:
	_sparks.restart()
	_sparks.emitting = true
	if body.is_in_group("paddle"):
		hit_paddle.emit(position)
	else:
		hit_wall.emit()

func _update_trail_speed() -> void:
	var ratio := _current_speed / MAX_SPEED
	_trail.speed_scale = 1.0 + ratio * 2.0
	_light.energy = 2.0 + ratio * 3.0
