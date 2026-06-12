extends Node2D

## Pokemon-style procedural tile renderer for generated towns!
## Receives town data from TownGenerator via setup(); draws everything
## in _draw() with a GBA-era look: chunky tiles, big roofs, bright palette.

const CELL := 48.0

var town: Dictionary = {}
var palette: Dictionary = {}
var anim_phase := 0
var _anim_timer := 0.0

const G := preload("res://systems/town_generator.gd")

# Base palette; styles override entries.
const BASE_PALETTE := {
	"grass":       Color("78c850"),
	"grass_dark":  Color("68b040"),
	"tuft":        Color("4e9433"),
	"flower_a":    Color("f85888"),
	"flower_b":    Color("f8d030"),
	"path":        Color("e0c068"),
	"path_dot":    Color("c8a858"),
	"road":        Color("9098a0"),
	"road_dark":   Color("787f88"),
	"road_line":   Color("f8f0d8"),
	"sidewalk":    Color("c8c0b0"),
	"sidewalk_line": Color("b0a890"),
	"plaza":       Color("d8d0c0"),
	"plaza_alt":   Color("c9c1ae"),
	"water":       Color("5090d8"),
	"water_deep":  Color("3870b8"),
	"wave":        Color("a8d0f8"),
	"sand":        Color("f0e0a0"),
	"trunk":       Color("8a5a2a"),
	"leaf":        Color("3e8e41"),
	"leaf_hi":     Color("5cb85f"),
	"fence":       Color("f8f8f0"),
	"fence_dark":  Color("c8c0b0"),
	"wall":        Color("f0e8d0"),
	"wall_dark":   Color("d8c8a8"),
	"window":      Color("a8d8f0"),
	"window_frame": Color("587088"),
	"door":        Color("9a6233"),
	"outline":     Color(0.15, 0.12, 0.1, 0.85),
	"roof_house":  [Color("e85048"), Color("4878d0"), Color("48a868")],
	"roof_hq":     Color("3a66c8"),
	"roof_civic":  Color("7858a8"),
	"roof_commercial": Color("e8a030"),
	"roof_diner":  Color("e85048"),
	"roof_factory": Color("806858"),
	"roof_barn":   Color("b03830"),
	"roof_tech":   Color("40b8c8"),
	"roof_weird":  Color("c858d8"),
	"roof_monument": Color("e8e8e0"),
}

const STYLE_OVERRIDES := {
	"industrial": {"grass": Color("8aa060"), "grass_dark": Color("7a9050"), "leaf": Color("567840"), "leaf_hi": Color("6e9050"), "wall": Color("c8b8a0"), "path": Color("b8a888")},
	"crime":      {"grass": Color("6a8858"), "grass_dark": Color("5a7848"), "road": Color("686d75"), "road_dark": Color("54585f"), "wall": Color("c0b8b0"), "plaza": Color("a8a098")},
	"coastal":    {"grass": Color("88cc70"), "sand": Color("f4e4a8"), "water": Color("48a0e0"), "water_deep": Color("3080c0")},
	"tourist":    {"grass": Color("90d068"), "water": Color("40b0e8"), "plaza": Color("f0e0c0"), "roof_commercial": Color("f06890")},
	"dream":      {"grass": Color("b088e0"), "grass_dark": Color("a078d0"), "leaf": Color("e878c0"), "leaf_hi": Color("f8a0d8"), "water": Color("d870e8"), "wave": Color("f8c0f8"), "path": Color("f8e8a0"), "plaza": Color("e8d0f8"), "flower_a": Color("f8f878")},
	"tech":       {"grass": Color("70c8a0"), "grass_dark": Color("60b890"), "plaza": Color("d0d8e0"), "path": Color("c0c8d0"), "wall": Color("e8eef4")},
	"rural":      {"grass": Color("80c050"), "path": Color("c8a868"), "fence": Color("b08850"), "fence_dark": Color("906838")},
	"university": {"grass": Color("70c060"), "wall": Color("d8a888"), "wall_dark": Color("c09070"), "roof_commercial": Color("c84858")},
	"capital":    {"plaza": Color("ece8dc"), "plaza_alt": Color("ddd8c8"), "wall": Color("f4f0e4"), "roof_civic": Color("486890")},
	"national":   {"plaza": Color("e8e0d0"), "roof_civic": Color("c03848")},
	"hometown":   {"flower_a": Color("f87878"), "flower_b": Color("f8e858")},
	"downtown":   {"grass": Color("74b85c"), "plaza": Color("c0bcb0")},
	"suburban":   {},
}


func setup(town_data: Dictionary) -> void:
	town = town_data
	palette = BASE_PALETTE.duplicate(true)
	var ov: Dictionary = STYLE_OVERRIDES.get(String(town.get("style", "suburban")), {})
	for k in ov:
		palette[k] = ov[k]
	queue_redraw()


func _process(delta: float) -> void:
	_anim_timer += delta
	if _anim_timer >= 0.45:
		_anim_timer = 0.0
		anim_phase = (anim_phase + 1) % 4
		queue_redraw()


func _draw() -> void:
	if town.is_empty():
		return
	var w := int(town.width)
	var h := int(town.height)

	# Pass 1: ground tiles
	for y in range(h):
		for x in range(w):
			_draw_ground(int(town.tiles[y][x]), x, y)

	# Pass 2: road markings
	_draw_road_lines()

	# Pass 3: fences, trees (top to bottom so canopies overlap nicely)
	for y in range(h):
		for x in range(w):
			var t := int(town.tiles[y][x])
			if t == G.T_FENCE:
				_draw_fence(x, y)
	for y in range(h):
		for x in range(w):
			if int(town.tiles[y][x]) == G.T_TREE:
				_draw_tree(x, y)

	# Pass 4: buildings (sorted by y so lower ones draw over)
	var blds: Array = (town.buildings as Array).duplicate()
	blds.sort_custom(func(a, b): return (a.rect as Rect2i).position.y < (b.rect as Rect2i).position.y)
	for b in blds:
		_draw_building(b)

	# Pass 5: props
	for p in town.props:
		_draw_prop(p)


# ------------------------------------------------------------------ ground

func _draw_ground(t: int, x: int, y: int) -> void:
	var r := Rect2(x * CELL, y * CELL, CELL, CELL)
	match t:
		G.T_GRASS, G.T_TUFT, G.T_FLOWER_A, G.T_FLOWER_B, G.T_TREE, G.T_FENCE:
			draw_rect(r, palette.grass)
			_grass_detail(r, x, y)
		G.T_GRASS_DARK:
			draw_rect(r, palette.grass_dark)
			_grass_detail(r, x, y)
		G.T_PATH:
			draw_rect(r, palette.path)
			for i in range(3):
				var px := r.position.x + fposmod(float(x * 31 + y * 17 + i * 19), CELL - 8.0) + 2.0
				var py := r.position.y + fposmod(float(x * 13 + y * 41 + i * 29), CELL - 8.0) + 2.0
				draw_rect(Rect2(px, py, 4, 3), palette.path_dot)
		G.T_ROAD:
			draw_rect(r, palette.road)
			if (x + y) % 7 == 0:
				draw_rect(Rect2(r.position + Vector2(10, 26), Vector2(8, 5)), palette.road_dark)
		G.T_SIDEWALK:
			draw_rect(r, palette.sidewalk)
			draw_rect(r, palette.sidewalk_line, false, 1.0)
		G.T_PLAZA:
			draw_rect(r, palette.plaza if (x + y) % 2 == 0 else palette.plaza_alt)
			draw_rect(r, Color(0, 0, 0, 0.05), false, 1.0)
		G.T_WATER:
			draw_rect(r, palette.water)
			# animated waves
			var ph := (x * 3 + y * 5 + anim_phase) % 4
			if ph == 0:
				draw_arc(r.position + Vector2(CELL * 0.5, CELL * 0.55), CELL * 0.22, PI * 1.15, PI * 1.85, 6, palette.wave, 2.5)
			elif ph == 2:
				draw_arc(r.position + Vector2(CELL * 0.3, CELL * 0.3), CELL * 0.16, PI * 1.15, PI * 1.85, 5, Color(palette.wave, 0.6), 2.0)
			if y + 1 < int(town.height) and int(town.tiles[y + 1][x]) == G.T_WATER:
				draw_rect(Rect2(r.position + Vector2(0, CELL - 6), Vector2(CELL, 6)), Color(palette.water_deep, 0.35))
		G.T_SAND:
			draw_rect(r, palette.sand)
			for i in range(4):
				var sx := r.position.x + fposmod(float(x * 23 + i * 31), CELL - 4.0)
				var sy := r.position.y + fposmod(float(y * 37 + i * 13), CELL - 4.0)
				draw_circle(Vector2(sx, sy), 1.5, Color(0, 0, 0, 0.08))
		G.T_BUILDING:
			draw_rect(r, palette.grass_dark)
		_:
			draw_rect(r, palette.grass)

	# Overlay decorations on top of grass
	match t:
		G.T_TUFT:
			_draw_tuft(r)
		G.T_FLOWER_A:
			_draw_flower(r, palette.flower_a)
		G.T_FLOWER_B:
			_draw_flower(r, palette.flower_b)


func _grass_detail(r: Rect2, x: int, y: int) -> void:
	# Little Pokemon-style v-marks
	var n := (x * 7 + y * 11) % 3 + 1
	for i in range(n):
		var gx := r.position.x + fposmod(float(x * 53 + i * 37 + y * 7), CELL - 12.0) + 4.0
		var gy := r.position.y + fposmod(float(y * 67 + i * 23 + x * 5), CELL - 12.0) + 4.0
		var c: Color = palette.tuft
		draw_line(Vector2(gx, gy + 4), Vector2(gx + 2.5, gy), c, 1.6)
		draw_line(Vector2(gx + 2.5, gy), Vector2(gx + 5, gy + 4), c, 1.6)


func _draw_tuft(r: Rect2) -> void:
	var cx := r.position.x + CELL * 0.5
	var by := r.position.y + CELL * 0.78
	var sway := 1.5 if anim_phase % 2 == 0 else -1.5
	var c: Color = palette.tuft
	draw_line(Vector2(cx - 7, by), Vector2(cx - 9 + sway, by - 13), c, 3.0)
	draw_line(Vector2(cx, by), Vector2(cx + sway, by - 17), c, 3.0)
	draw_line(Vector2(cx + 7, by), Vector2(cx + 9 + sway, by - 12), c, 3.0)


func _draw_flower(r: Rect2, col: Color) -> void:
	var c := r.position + Vector2(CELL * 0.5, CELL * 0.5)
	var wob := 1.0 if anim_phase % 2 == 0 else -1.0
	for a in range(4):
		var ang := a * PI / 2.0 + wob * 0.12
		draw_circle(c + Vector2.from_angle(ang) * 5.0, 4.0, col)
	draw_circle(c, 3.4, Color("f8f8c8"))


func _draw_road_lines() -> void:
	var road_y := int(town.get("road_y", -10))
	var road_x := int(town.get("road_x", -10))
	var w := int(town.width)
	var h := int(town.height)
	if road_y >= 0:
		var ly := (road_y + 1) * CELL
		for i in range(w * 2):
			if i % 3 != 2:
				draw_rect(Rect2(i * CELL * 0.5 + 4, ly - 2.5, CELL * 0.5 - 12, 5), palette.road_line)
	if road_x >= 0:
		var lx := (road_x + 1) * CELL
		for i in range(h * 2):
			if i % 3 != 2:
				var cy := i * CELL * 0.5
				var ty := int(cy / CELL)
				if ty >= 0 and ty < h and int(town.tiles[ty][road_x]) == G.T_ROAD:
					draw_rect(Rect2(lx - 2.5, cy + 4, 5, CELL * 0.5 - 12), palette.road_line)


# ------------------------------------------------------------------ flora & fences

func _draw_tree(x: int, y: int) -> void:
	var base := Vector2((x + 0.5) * CELL, (y + 0.9) * CELL)
	# shadow
	draw_circle(base + Vector2(0, -2), CELL * 0.3, Color(0, 0, 0, 0.15))
	# trunk
	draw_rect(Rect2(base.x - 5, base.y - CELL * 0.55, 10, CELL * 0.5), palette.trunk)
	# canopy: stacked blobs
	var leaf: Color = palette.leaf
	var hi: Color = palette.leaf_hi
	draw_circle(base + Vector2(-10, -CELL * 0.62), CELL * 0.3, leaf)
	draw_circle(base + Vector2(10, -CELL * 0.62), CELL * 0.3, leaf)
	draw_circle(base + Vector2(0, -CELL * 0.86), CELL * 0.34, leaf)
	draw_circle(base + Vector2(-5, -CELL * 0.92), CELL * 0.16, hi)
	draw_circle(base + Vector2(9, -CELL * 0.7), CELL * 0.12, hi)


func _draw_fence(x: int, y: int) -> void:
	var r := Rect2(x * CELL, y * CELL, CELL, CELL)
	var c: Color = palette.fence
	var cd: Color = palette.fence_dark
	# horizontal rail
	draw_rect(Rect2(r.position.x, r.position.y + CELL * 0.45, CELL, 5), cd)
	# pickets
	for i in range(3):
		var px := r.position.x + 6 + i * (CELL - 16) / 2.0
		draw_rect(Rect2(px, r.position.y + CELL * 0.25, 7, CELL * 0.5), c)
		draw_rect(Rect2(px, r.position.y + CELL * 0.25, 7, CELL * 0.5), Color(0, 0, 0, 0.25), false, 1.0)


# ------------------------------------------------------------------ buildings

func _draw_building(b: Dictionary) -> void:
	var rect: Rect2i = b.rect
	var kind := String(b.kind)
	var px := Rect2(rect.position.x * CELL, rect.position.y * CELL, rect.size.x * CELL, rect.size.y * CELL)
	var outline: Color = palette.outline

	var roof_col: Color
	match kind:
		"house":
			var roofs: Array = palette.roof_house
			roof_col = roofs[int(b.get("variant", 0)) % roofs.size()]
		"hq": roof_col = palette.roof_hq
		"civic": roof_col = palette.roof_civic
		"commercial": roof_col = palette.roof_commercial
		"diner": roof_col = palette.roof_diner
		"factory": roof_col = palette.roof_factory
		"barn": roof_col = palette.roof_barn
		"tech": roof_col = palette.roof_tech
		"weird": roof_col = palette.roof_weird
		"monument": roof_col = palette.roof_monument
		_: roof_col = palette.roof_commercial

	var wall: Color = palette.wall
	if kind == "factory":
		wall = Color("b08868")
	elif kind == "barn":
		wall = Color("c04840")
	elif kind == "tech":
		wall = Color("e0ecf4")
	elif kind == "civic" or kind == "monument":
		wall = Color("f0ece0")

	# Shadow
	draw_rect(Rect2(px.position + Vector2(4, 6), px.size), Color(0, 0, 0, 0.18))

	var roof_h := px.size.y * 0.42
	var wall_rect := Rect2(px.position + Vector2(0, roof_h), Vector2(px.size.x, px.size.y - roof_h))

	# Wall
	draw_rect(wall_rect, wall)
	draw_rect(Rect2(wall_rect.position + Vector2(0, wall_rect.size.y - 7), Vector2(wall_rect.size.x, 7)), palette.wall_dark)
	draw_rect(wall_rect, outline, false, 2.0)

	# Roof (overhanging trapezoid, very Pokemon)
	var ov := 7.0
	var roof_pts := PackedVector2Array([
		Vector2(px.position.x - ov, px.position.y + roof_h),
		Vector2(px.position.x + px.size.x * 0.13, px.position.y),
		Vector2(px.position.x + px.size.x * 0.87, px.position.y),
		Vector2(px.position.x + px.size.x + ov, px.position.y + roof_h),
	])
	draw_colored_polygon(roof_pts, roof_col)
	draw_polyline(roof_pts, outline, 2.0)
	draw_line(roof_pts[0], roof_pts[3], outline, 2.0)
	# Roof ridge highlight
	draw_line(
		Vector2(px.position.x + px.size.x * 0.16, px.position.y + 5),
		Vector2(px.position.x + px.size.x * 0.84, px.position.y + 5),
		Color(1, 1, 1, 0.25), 3.0)

	# Door (aligned with door cell)
	var door_cell: Vector2i = b.door
	var dx := (door_cell.x + 0.5) * CELL
	var door_w := CELL * 0.42
	var door_h := wall_rect.size.y * 0.58
	var door_rect := Rect2(dx - door_w / 2, wall_rect.end.y - door_h, door_w, door_h)
	draw_rect(door_rect, palette.door)
	draw_rect(door_rect, outline, false, 2.0)
	draw_circle(Vector2(door_rect.end.x - 5, door_rect.position.y + door_h * 0.55), 2.2, Color("f8d030"))
	# Doormat
	draw_rect(Rect2(dx - door_w / 2, wall_rect.end.y, door_w, 6), Color("c8a858"))

	# Windows on the wall, skipping door area
	var win: Color = palette.window
	var wf: Color = palette.window_frame
	var n_win := int(px.size.x / (CELL * 1.1))
	for i in range(n_win):
		var wx := px.position.x + (i + 0.5) * px.size.x / n_win - CELL * 0.2
		var wrect := Rect2(wx, wall_rect.position.y + 8, CELL * 0.4, CELL * 0.36)
		if wrect.intersects(door_rect.grow(6)):
			continue
		draw_rect(wrect, win)
		draw_rect(wrect, wf, false, 2.0)
		draw_line(wrect.position + Vector2(wrect.size.x / 2, 0), wrect.position + Vector2(wrect.size.x / 2, wrect.size.y), wf, 1.5)

	# Kind-specific garnish
	match kind:
		"hq":
			_banner(px, Color("3a66c8"), "VOTE")
		"civic":
			# columns + flag
			for i in range(2):
				var cx := px.position.x + px.size.x * (0.22 + 0.56 * i)
				draw_rect(Rect2(cx - 4, wall_rect.position.y, 8, wall_rect.size.y), Color("e8e4d8"))
				draw_rect(Rect2(cx - 4, wall_rect.position.y, 8, wall_rect.size.y), outline, false, 1.0)
			var fp := Vector2(px.position.x + px.size.x / 2, px.position.y - 18)
			draw_line(fp, fp + Vector2(0, 18), outline, 2.0)
			draw_rect(Rect2(fp + Vector2(1, 0), Vector2(13, 8)), Color("e03030"))
		"diner":
			_awning(px, wall_rect, Color("e85048"))
		"commercial":
			_awning(px, wall_rect, Color("48a868"))
		"factory":
			for i in range(2):
				var sx := px.position.x + px.size.x * (0.3 + 0.4 * i)
				draw_rect(Rect2(sx - 6, px.position.y - 20, 12, 24), Color("6a5444"))
				draw_rect(Rect2(sx - 6, px.position.y - 20, 12, 24), outline, false, 1.5)
				var puff := (anim_phase + i * 2) % 4
				draw_circle(Vector2(sx, px.position.y - 26 - puff * 4), 5 + puff * 1.5, Color(0.8, 0.8, 0.8, 0.5 - puff * 0.1))
		"barn":
			# big X doors
			draw_line(door_rect.position, door_rect.position + door_rect.size, Color("f8f0d8"), 3.0)
			draw_line(Vector2(door_rect.end.x, door_rect.position.y), Vector2(door_rect.position.x, door_rect.end.y), Color("f8f0d8"), 3.0)
		"tech":
			# antenna with blinking light
			var ap := Vector2(px.position.x + px.size.x * 0.8, px.position.y - 16)
			draw_line(ap, ap + Vector2(0, 16), outline, 2.0)
			draw_circle(ap, 4.0, Color("f85858") if anim_phase % 2 == 0 else Color("802020"))
		"weird":
			# a door on the ROOF. why not. it's a dream.
			draw_rect(Rect2(px.position.x + px.size.x * 0.45, px.position.y + 4, CELL * 0.3, CELL * 0.34), palette.door)
		"monument":
			var mp := Vector2(px.position.x + px.size.x / 2, px.position.y)
			draw_colored_polygon(PackedVector2Array([
				mp + Vector2(-8, 0), mp + Vector2(0, -30), mp + Vector2(8, 0)
			]), Color("f0ece0"))


func _awning(px: Rect2, wall_rect: Rect2, col: Color) -> void:
	var aw := Rect2(px.position.x + 4, wall_rect.position.y - 4, px.size.x - 8, 12)
	var stripes := int(aw.size.x / 14)
	for i in range(stripes):
		var sc := col if i % 2 == 0 else Color("f8f4e8")
		draw_rect(Rect2(aw.position.x + i * aw.size.x / stripes, aw.position.y, aw.size.x / stripes + 1, aw.size.y), sc)
	draw_rect(aw, palette.outline, false, 1.5)


func _banner(px: Rect2, col: Color, text: String) -> void:
	var bw := 56.0
	var bh := 18.0
	var bp := Vector2(px.position.x + px.size.x / 2 - bw / 2, px.position.y - bh - 4)
	draw_rect(Rect2(bp, Vector2(bw, bh)), col)
	draw_rect(Rect2(bp, Vector2(bw, bh)), palette.outline, false, 2.0)
	var font := ThemeDB.fallback_font
	draw_string(font, bp + Vector2(8, bh - 4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)


# ------------------------------------------------------------------ props

func _draw_prop(p: Dictionary) -> void:
	var cell: Vector2i = p.cell
	var c := Vector2((cell.x + 0.5) * CELL, (cell.y + 0.5) * CELL)
	var outline: Color = palette.outline
	match String(p.kind):
		"fountain":
			draw_circle(c, CELL * 0.42, Color("b8c4cc"))
			draw_circle(c, CELL * 0.42, outline, false, 2.0)
			draw_circle(c, CELL * 0.3, palette.water)
			var spray := 3.0 + anim_phase * 2.0
			draw_circle(c + Vector2(0, -spray), 4.0, palette.wave)
			draw_circle(c + Vector2(-6, -spray + 3), 2.5, Color(palette.wave, 0.7))
			draw_circle(c + Vector2(6, -spray + 3), 2.5, Color(palette.wave, 0.7))
		"stage":
			var r := Rect2(cell.x * CELL, cell.y * CELL + 8, CELL, CELL - 12)
			draw_rect(r, Color("a87848"))
			draw_rect(r, outline, false, 2.0)
			for i in range(3):
				draw_circle(Vector2(r.position.x + 8 + i * 16, r.position.y), 4, [Color("e85048"), Color("f8d030"), Color("4878d0")][i % 3])
		"bench":
			var r := Rect2(c.x - 18, c.y - 6, 36, 12)
			draw_rect(r, Color("b08850"))
			draw_rect(r, outline, false, 1.5)
			draw_rect(Rect2(c.x - 16, c.y + 6, 5, 5), Color("806030"))
			draw_rect(Rect2(c.x + 11, c.y + 6, 5, 5), Color("806030"))
		"lamppost":
			draw_line(c + Vector2(0, 14), c + Vector2(0, -18), Color("485058"), 4.0)
			draw_circle(c + Vector2(0, -20), 6.0, Color("f8e8a0"))
			draw_circle(c + Vector2(0, -20), 6.0, outline, false, 1.5)
		"trash_can":
			draw_rect(Rect2(c.x - 8, c.y - 10, 16, 20), Color("687078"))
			draw_rect(Rect2(c.x - 10, c.y - 13, 20, 5), Color("505860"))
			draw_rect(Rect2(c.x - 8, c.y - 10, 16, 20), outline, false, 1.5)
		"mailbox":
			draw_line(c + Vector2(0, 12), c + Vector2(0, -2), Color("806030"), 4.0)
			draw_rect(Rect2(c.x - 9, c.y - 14, 18, 12), Color("4878d0"))
			draw_rect(Rect2(c.x - 9, c.y - 14, 18, 12), outline, false, 1.5)
		"barrel":
			draw_rect(Rect2(c.x - 9, c.y - 11, 18, 22), Color("8a6a3a"))
			draw_rect(Rect2(c.x - 9, c.y - 5, 18, 3), Color("60482a"))
			draw_rect(Rect2(c.x - 9, c.y + 3, 18, 3), Color("60482a"))
			draw_rect(Rect2(c.x - 9, c.y - 11, 18, 22), outline, false, 1.5)
		"server_box":
			draw_rect(Rect2(c.x - 10, c.y - 12, 20, 24), Color("485058"))
			for i in range(3):
				var on := (anim_phase + i) % 3 == 0
				draw_circle(Vector2(c.x - 4 + i * 5, c.y - 6), 2.0, Color("58f858") if on else Color("204020"))
			draw_rect(Rect2(c.x - 10, c.y - 12, 20, 24), outline, false, 1.5)
		"statue":
			draw_rect(Rect2(c.x - 10, c.y + 2, 20, 10), Color("b8b4a8"))
			draw_rect(Rect2(c.x - 5, c.y - 16, 10, 18), Color("c8c4b8"))
			draw_circle(Vector2(c.x, c.y - 20), 5.0, Color("c8c4b8"))
			draw_rect(Rect2(c.x - 10, c.y + 2, 20, 10), outline, false, 1.5)
		"duck_sign":
			draw_line(c + Vector2(0, 12), c + Vector2(0, -4), Color("806030"), 3.0)
			draw_rect(Rect2(c.x - 14, c.y - 16, 28, 13), Color("e8d8a8"))
			draw_rect(Rect2(c.x - 14, c.y - 16, 28, 13), outline, false, 1.5)
			var font := ThemeDB.fallback_font
			draw_string(font, Vector2(c.x - 11, c.y - 6), "DUCKS", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("604820"))
