extends Node2D

## A townsperson (or duck) that wanders the generated town and says things.
## town.gd owns the collision data and passes a walkability check in.

const CELL := 48.0
const AVATAR_SCRIPT := preload("res://scripts/character_avatar.gd")

var npc_name := "Local"
var lines: Array = []
var grid_cell: Vector2i
var home_cell: Vector2i
var wander_radius := 4
var is_walker := true
var walkable_check: Callable = Callable()
var occupied_check: Callable = Callable()

var avatar: Node2D
var _wander_timer := 0.0
var _next_wander := 1.5
var _is_moving := false
var _line_index := -1
var _rng := RandomNumberGenerator.new()


func setup(config: Dictionary) -> void:
	npc_name = config.get("name", "Local")
	lines = config.get("lines", [])
	home_cell = config.get("cell", Vector2i(2, 2))
	grid_cell = home_cell
	is_walker = config.get("walker", true)
	wander_radius = config.get("radius", 4)
	walkable_check = config.get("walkable_check", Callable())
	occupied_check = config.get("occupied_check", Callable())
	_rng.seed = hash(npc_name) + home_cell.x * 97 + home_cell.y

	position = Vector2(grid_cell.x * CELL, grid_cell.y * CELL)

	avatar = Node2D.new()
	avatar.set_script(AVATAR_SCRIPT)
	add_child(avatar)
	avatar.set_palette(config.get("palette", {}))
	if config.has("facing"):
		avatar.facing = config.facing
	_next_wander = _rng.randf_range(1.0, 3.0)


func _process(delta: float) -> void:
	if not is_walker or _is_moving:
		return
	_wander_timer += delta
	if _wander_timer >= _next_wander:
		_wander_timer = 0.0
		_next_wander = _rng.randf_range(1.2, 3.2)
		_try_wander()


func _try_wander() -> void:
	var dirs := [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	var dir: Vector2i = dirs[_rng.randi_range(0, 3)]
	var target := grid_cell + dir
	if Vector2(target).distance_to(Vector2(home_cell)) > float(wander_radius):
		return
	if walkable_check.is_valid() and not walkable_check.call(target):
		return
	if occupied_check.is_valid() and occupied_check.call(target, self):
		return

	avatar.facing = dir
	avatar.moving = true
	_is_moving = true
	grid_cell = target
	var tw := create_tween()
	tw.tween_property(self, "position", Vector2(target.x * CELL, target.y * CELL), 0.35)
	tw.finished.connect(func() -> void:
		_is_moving = false
		avatar.moving = false
	)


func face_towards(cell: Vector2i) -> void:
	var d := cell - grid_cell
	if absi(d.x) >= absi(d.y):
		avatar.facing = Vector2i.RIGHT if d.x > 0 else Vector2i.LEFT
	else:
		avatar.facing = Vector2i.DOWN if d.y > 0 else Vector2i.UP
	avatar.queue_redraw()


func next_line() -> String:
	if lines.is_empty():
		return "..."
	_line_index = (_line_index + 1) % lines.size()
	return String(lines[_line_index])
