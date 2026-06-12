extends Node2D

signal interact_requested(target_cell: Vector2i)
signal stepped(cell: Vector2i)

@export var cell_size: int = 48
@export var move_time: float = 0.16

@onready var camera: Camera2D = $Camera2D

const AVATAR_SCRIPT := preload("res://scripts/character_avatar.gd")

var grid_cell: Vector2i
var facing: Vector2i = Vector2i.DOWN
var is_moving := false
var input_locked := false

var bounds_min: Vector2i = Vector2i(0, 0)
var bounds_max: Vector2i = Vector2i(29, 18)
var walkable_check: Callable = Callable()

var avatar: Node2D

# Hold-to-move: initial delay before repeating, then fast repeat interval.
const HOLD_INITIAL_DELAY := 0.22
const HOLD_REPEAT_INTERVAL := 0.02
var _held_dir: Vector2i = Vector2i.ZERO
var _move_cooldown: float = 0.0

const DIRS := {
	"move_up": Vector2i.UP,
	"move_down": Vector2i.DOWN,
	"move_left": Vector2i.LEFT,
	"move_right": Vector2i.RIGHT,
}


func _ready() -> void:
	_ensure_input_actions()
	avatar = Node2D.new()
	avatar.set_script(AVATAR_SCRIPT)
	add_child(avatar)


func configure(start_cell: Vector2i, min_b: Vector2i, max_b: Vector2i, walk_check: Callable) -> void:
	grid_cell = start_cell
	bounds_min = min_b
	bounds_max = max_b
	walkable_check = walk_check
	global_position = _cell_to_pos(grid_cell)
	_setup_camera_limits()


func _process(delta: float) -> void:
	if is_moving or input_locked:
		return

	if Input.is_action_just_pressed("ui_accept"):
		interact_requested.emit(grid_cell + facing)
		_held_dir = Vector2i.ZERO
		_move_cooldown = 0.0
		return

	if _move_cooldown > 0.0:
		_move_cooldown -= delta

	var dir := _get_held_dir()

	if dir == Vector2i.ZERO:
		_held_dir = Vector2i.ZERO
		_move_cooldown = 0.0
		avatar.moving = false
		return

	if dir != _held_dir:
		_held_dir = dir
		_move_cooldown = HOLD_INITIAL_DELAY
		_try_move(dir)
	elif _move_cooldown <= 0.0:
		_move_cooldown = HOLD_REPEAT_INTERVAL
		_try_move(dir)


func _get_held_dir() -> Vector2i:
	for action in DIRS:
		if Input.is_action_pressed(action):
			return DIRS[action]
	return Vector2i.ZERO


func _is_cell_blocked(cell: Vector2i) -> bool:
	if walkable_check.is_valid():
		return not walkable_check.call(cell)
	return false


func _try_move(dir: Vector2i) -> void:
	facing = dir
	avatar.facing = dir
	avatar.queue_redraw()
	var target := grid_cell + dir
	if target.x < bounds_min.x or target.x > bounds_max.x:
		return
	if target.y < bounds_min.y or target.y > bounds_max.y:
		return
	if _is_cell_blocked(target):
		return

	is_moving = true
	avatar.moving = true
	grid_cell = target
	var tween := create_tween()
	tween.tween_property(self, "global_position", _cell_to_pos(grid_cell), move_time)
	await tween.finished
	is_moving = false
	stepped.emit(grid_cell)
	if _get_held_dir() == Vector2i.ZERO:
		avatar.moving = false


func _cell_to_pos(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * cell_size, cell.y * cell_size)


const ZOOM_DEFAULT := 1.45
const ZOOM_MIN := 1.0
const ZOOM_MAX := 2.0
const ZOOM_STEP := 0.15


func _unhandled_input(event: InputEvent) -> void:
	# Camera zoom: mouse wheel or +/- keys.
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_adjust_zoom(ZOOM_STEP)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_adjust_zoom(-ZOOM_STEP)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_EQUAL or event.keycode == KEY_KP_ADD:
			_adjust_zoom(ZOOM_STEP)
		elif event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
			_adjust_zoom(-ZOOM_STEP)


func _adjust_zoom(delta: float) -> void:
	var z: float = clampf(camera.zoom.x + delta, ZOOM_MIN, ZOOM_MAX)
	var tw := create_tween()
	tw.tween_property(camera, "zoom", Vector2(z, z), 0.12)


func _setup_camera_limits() -> void:
	camera.make_current()
	camera.zoom = Vector2(ZOOM_DEFAULT, ZOOM_DEFAULT)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.limit_left = bounds_min.x * cell_size
	camera.limit_top = bounds_min.y * cell_size
	camera.limit_right = (bounds_max.x + 1) * cell_size
	camera.limit_bottom = (bounds_max.y + 1) * cell_size
	# Center camera on the avatar sprite rather than node origin
	camera.position = Vector2(cell_size * 0.5, cell_size * 0.5)
	camera.reset_smoothing()


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
