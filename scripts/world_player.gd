extends Node2D

signal interact_requested(target_cell: Vector2i)

@export var cell_size: int = 64
@export var move_time: float = 0.14
@export var bounds_min: Vector2i = Vector2i(1, 1)
@export var bounds_max: Vector2i = Vector2i(18, 10)
@export var start_cell: Vector2i = Vector2i(3, 7)

@onready var camera: Camera2D = $Camera2D

var grid_cell: Vector2i
var facing: Vector2i = Vector2i.RIGHT
var is_moving := false

# Hold-to-move: initial delay before repeating, then fast repeat interval.
const HOLD_INITIAL_DELAY := 0.28
const HOLD_REPEAT_INTERVAL := 0.10
var _held_dir: Vector2i = Vector2i.ZERO
var _move_cooldown: float = 0.0

const DIRS := {
	"move_up": Vector2i.UP,
	"move_down": Vector2i.DOWN,
	"move_left": Vector2i.LEFT,
	"move_right": Vector2i.RIGHT,
}

# Building footprints the player cannot walk into.
# Each Rect2i is (origin_cell, size_in_cells).
const BLOCKED_ZONES: Array[Rect2i] = [
	Rect2i(1, 1, 5, 3),   # Residential / Neighborhood block
	Rect2i(12, 1, 6, 3),  # Commercial / Print Shop block
	Rect2i(12, 8, 6, 3),  # Civic block
]


func _ready() -> void:
	_ensure_input_actions()
	grid_cell = start_cell
	global_position = _cell_to_pos(grid_cell)
	_setup_camera_limits()


func _process(delta: float) -> void:
	if is_moving:
		return

	if Input.is_action_just_pressed("ui_accept"):
		interact_requested.emit(grid_cell + facing)
		_held_dir = Vector2i.ZERO
		_move_cooldown = 0.0
		return

	# Count down repeat cooldown.
	if _move_cooldown > 0.0:
		_move_cooldown -= delta

	var dir := _get_held_dir()

	if dir == Vector2i.ZERO:
		_held_dir = Vector2i.ZERO
		_move_cooldown = 0.0
		return

	if dir != _held_dir:
		# New direction: move immediately, then wait the initial delay.
		_held_dir = dir
		_move_cooldown = HOLD_INITIAL_DELAY
		_try_move(dir)
	elif _move_cooldown <= 0.0:
		# Same direction held and cooldown elapsed: repeat move.
		_move_cooldown = HOLD_REPEAT_INTERVAL
		_try_move(dir)


func _get_held_dir() -> Vector2i:
	for action in DIRS:
		if Input.is_action_pressed(action):
			return DIRS[action]
	return Vector2i.ZERO


func _is_cell_blocked(cell: Vector2i) -> bool:
	for zone in BLOCKED_ZONES:
		if zone.has_point(cell):
			return true
	return false


func _try_move(dir: Vector2i) -> void:
	facing = dir
	var target := grid_cell + dir
	if target.x < bounds_min.x or target.x > bounds_max.x:
		return
	if target.y < bounds_min.y or target.y > bounds_max.y:
		return
	if _is_cell_blocked(target):
		return

	is_moving = true
	grid_cell = target
	var tween := create_tween()
	tween.tween_property(self, "global_position", _cell_to_pos(grid_cell), move_time)
	await tween.finished
	is_moving = false


func _cell_to_pos(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * cell_size, cell.y * cell_size)


func _setup_camera_limits() -> void:
	camera.make_current()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.limit_left = bounds_min.x * cell_size
	camera.limit_top = bounds_min.y * cell_size
	camera.limit_right = (bounds_max.x + 1) * cell_size
	camera.limit_bottom = (bounds_max.y + 1) * cell_size


func _ensure_input_actions() -> void:
	_ensure_action_with_key("move_up", KEY_W)
	_ensure_action_with_key("move_up", KEY_UP)
	_ensure_action_with_key("move_down", KEY_S)
	_ensure_action_with_key("move_down", KEY_DOWN)
	_ensure_action_with_key("move_left", KEY_A)
	_ensure_action_with_key("move_left", KEY_LEFT)
	_ensure_action_with_key("move_right", KEY_D)
	_ensure_action_with_key("move_right", KEY_RIGHT)


func _ensure_action_with_key(action_name: String, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey and event.keycode == keycode:
			return

	var key_event := InputEventKey.new()
	key_event.keycode = keycode
	InputMap.action_add_event(action_name, key_event)
