extends Node2D

## Procedurally drawn chibi character (Pokemon trainer style).
## Used by the player and by town NPCs with different palettes.
## Parent sets `facing` and `moving`; this node handles the walk bob.

const CELL := 48.0

var facing: Vector2i = Vector2i.DOWN
var moving := false
var walk_phase := 0.0

# Palette
var skin := Color("f0c8a0")
var hair := Color("5a3a20")
var shirt := Color("e84840")
var pants := Color("3858a0")
var hat_color := Color("e84840")
var has_hat := true
var is_duck := false

var _bob_t := 0.0


func set_palette(p: Dictionary) -> void:
	skin = p.get("skin", skin)
	hair = p.get("hair", hair)
	shirt = p.get("shirt", shirt)
	pants = p.get("pants", pants)
	hat_color = p.get("hat", hat_color)
	has_hat = p.get("has_hat", has_hat)
	is_duck = p.get("is_duck", false)
	queue_redraw()


func _process(delta: float) -> void:
	if moving:
		_bob_t += delta * 10.0
		walk_phase = sin(_bob_t)
		queue_redraw()
	elif absf(walk_phase) > 0.01:
		walk_phase = 0.0
		queue_redraw()


func _draw() -> void:
	var c := Vector2(CELL * 0.5, CELL * 0.55)
	if is_duck:
		_draw_duck(c)
		return

	var bob := -absf(walk_phase) * 2.0
	var outline := Color(0.12, 0.1, 0.08, 0.9)

	# Shadow
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2(c.x, (c.y + 16) / 0.45), 11.0, Color(0, 0, 0, 0.22))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Legs
	var leg_off := walk_phase * 3.5
	draw_rect(Rect2(c.x - 7, c.y + 6 + bob + maxf(leg_off, 0) * 0.6, 6, 9 - maxf(leg_off, 0) * 0.6), pants)
	draw_rect(Rect2(c.x + 1, c.y + 6 + bob + maxf(-leg_off, 0) * 0.6, 6, 9 - maxf(-leg_off, 0) * 0.6), pants)

	# Body
	var body := Rect2(c.x - 9, c.y - 6 + bob, 18, 14)
	draw_rect(body, shirt)
	draw_rect(body, outline, false, 1.5)

	# Arms
	var arm_off := -walk_phase * 2.0 if facing.x == 0 else 0.0
	draw_rect(Rect2(c.x - 12, c.y - 4 + bob + arm_off, 4, 9), shirt)
	draw_rect(Rect2(c.x + 8, c.y - 4 + bob - arm_off, 4, 9), shirt)
	draw_circle(Vector2(c.x - 10, c.y + 6 + bob + arm_off), 2.2, skin)
	draw_circle(Vector2(c.x + 10, c.y + 6 + bob - arm_off), 2.2, skin)

	# Head
	var head_c := Vector2(c.x, c.y - 14 + bob)
	draw_circle(head_c, 10.5, skin)
	draw_circle(head_c, 10.5, outline, false, 1.5)

	# Hair / hat / face depend on facing
	if facing == Vector2i.UP:
		# Back of head: hair covers most
		draw_circle(head_c + Vector2(0, -1), 9.5, hair)
	else:
		# Hair top
		draw_arc(head_c, 9.0, PI, TAU, 12, hair, 5.0)
		var eye_y := head_c.y + 1
		if facing == Vector2i.DOWN:
			draw_circle(Vector2(head_c.x - 4, eye_y), 1.7, Color.BLACK)
			draw_circle(Vector2(head_c.x + 4, eye_y), 1.7, Color.BLACK)
		elif facing == Vector2i.LEFT:
			draw_circle(Vector2(head_c.x - 5, eye_y), 1.7, Color.BLACK)
		elif facing == Vector2i.RIGHT:
			draw_circle(Vector2(head_c.x + 5, eye_y), 1.7, Color.BLACK)

	if has_hat:
		# Cap dome
		draw_arc(head_c + Vector2(0, -3), 9.0, PI, TAU, 12, hat_color, 7.0)
		# Brim points where we face
		var brim_dir := Vector2(facing.x, 0)
		if facing == Vector2i.DOWN:
			brim_dir = Vector2(0, 0.4)
			draw_rect(Rect2(head_c.x - 9, head_c.y - 7, 18, 4), hat_color)
			draw_rect(Rect2(head_c.x - 7, head_c.y - 5, 14, 3), Color(hat_color.darkened(0.25)))
		elif facing == Vector2i.UP:
			draw_rect(Rect2(head_c.x - 9, head_c.y - 8, 18, 4), hat_color)
		else:
			draw_rect(Rect2(head_c.x - 9, head_c.y - 7, 18, 4), hat_color)
			var bx := head_c.x + (7 if facing == Vector2i.RIGHT else -13)
			draw_rect(Rect2(bx, head_c.y - 6, 6, 3.5), Color(hat_color.darkened(0.25)))


func _draw_duck(c: Vector2) -> void:
	var bob := -absf(walk_phase) * 1.5
	var body_col := Color("f8e858")
	var outline := Color(0.3, 0.25, 0.05, 0.9)
	# Shadow
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2(c.x, (c.y + 12) / 0.45), 8.0, Color(0, 0, 0, 0.18))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Body
	draw_circle(Vector2(c.x, c.y + 4 + bob), 8.0, body_col)
	draw_circle(Vector2(c.x, c.y + 4 + bob), 8.0, outline, false, 1.2)
	# Head
	var hx := c.x + (5 if facing != Vector2i.LEFT else -5)
	draw_circle(Vector2(hx, c.y - 5 + bob), 5.5, body_col)
	draw_circle(Vector2(hx, c.y - 5 + bob), 5.5, outline, false, 1.2)
	# Bill
	var bdir := -1.0 if facing == Vector2i.LEFT else 1.0
	draw_rect(Rect2(hx + bdir * 4 - (3 if bdir < 0 else 0), c.y - 5 + bob, 6, 3), Color("f8a030"))
	# Eye
	draw_circle(Vector2(hx + bdir * 2, c.y - 7 + bob), 1.2, Color.BLACK)
	# Wing
	draw_arc(Vector2(c.x - bdir * 2, c.y + 4 + bob), 4.0, 0, PI, 8, Color("e8d040"), 2.0)
