extends Node2D

@export var cell_size: int = 64
@export var width_cells: int = 20
@export var height_cells: int = 12


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	var cs := float(cell_size)
	var w := width_cells * cs
	var h := height_cells * cs
	var mode := String(SettingsSystem.get_value("colorblind_mode", "off"))

	# --- Palette ---
	var c_grass       := Color("3a7d44")
	var c_grass_dark  := Color("2e6438")
	var c_road        := Color("5a5a62")
	var c_road_mark   := Color("e8e060", 0.85)
	var c_sidewalk    := Color("8e8e7a")
	var c_residential := Color("c8784a")
	var c_residential_roof := Color("9e5230")
	var c_commercial  := Color("4a7ab5")
	var c_commercial_roof  := Color("2d5a8e")
	var c_civic       := Color("7a5a9e")
	var c_civic_roof  := Color("5a3a7e")
	var c_park        := Color("4a9e5a")
	var c_window      := Color("cceeff", 0.85)
	var c_door        := Color("3a2010")
	var c_outline     := Color(0, 0, 0, 0.55)

	if mode == "deuteranopia":
		c_grass = Color("4a6e54")
		c_residential = Color("c8942a")
		c_commercial  = Color("4a8ab5")
		c_civic       = Color("8a6aae")
	elif mode == "high_contrast":
		c_grass = Color("1a5a22")
		c_road  = Color("2a2a32")
		c_road_mark = Color.WHITE
		c_residential = Color("ff8040")
		c_commercial  = Color("40aaff")
		c_civic       = Color("cc60ff")

	# ---- GROUND BASE ----
	# Checker grass variation for visual texture
	for gy in range(height_cells):
		for gx in range(width_cells):
			var col := c_grass if (gx + gy) % 2 == 0 else c_grass_dark
			draw_rect(Rect2(gx * cs, gy * cs, cs, cs), col)

	# ---- SIDEWALKS (border around roads) ----
	draw_rect(Rect2(0, 4.75 * cs, w, 0.25 * cs), c_sidewalk)
	draw_rect(Rect2(0, 7.0 * cs,  w, 0.25 * cs), c_sidewalk)
	draw_rect(Rect2(7.75 * cs, 0, 0.25 * cs, h), c_sidewalk)
	draw_rect(Rect2(10.0 * cs, 0, 0.25 * cs, h), c_sidewalk)

	# ---- ROADS ----
	draw_rect(Rect2(0,      5.0 * cs, w,        2.0 * cs), c_road)
	draw_rect(Rect2(8.0 * cs, 0,     2.0 * cs,  h        ), c_road)

	# Road centre dashes — horizontal
	for i in range(0, width_cells * 2):
		if i % 4 < 2:
			var sx := i * cs * 0.5
			draw_rect(Rect2(sx, 5.9 * cs, cs * 0.5 - 4, 4), c_road_mark)
	# Road centre dashes — vertical
	for i in range(0, height_cells * 2):
		if i % 4 < 2:
			var sy := i * cs * 0.5
			draw_rect(Rect2(8.9 * cs, sy, 4, cs * 0.5 - 4), c_road_mark)

	# Intersection box
	draw_rect(Rect2(8.0 * cs, 5.0 * cs, 2.0 * cs, 2.0 * cs), c_road)

	# ---- DISTRICT BLOCK A: Neighborhood (houses) ----
	_draw_block(Rect2(1 * cs, 1 * cs, 5 * cs, 3 * cs), c_residential, c_residential_roof, c_window, c_door, c_outline, cs, "house")

	# ---- DISTRICT BLOCK B: Print Shop / Commercial (left of centre, upper) ----
	_draw_block(Rect2(12 * cs, 1 * cs, 6 * cs, 3 * cs), c_commercial, c_commercial_roof, c_window, c_door, c_outline, cs, "office")

	# ---- DISTRICT BLOCK C: Civic (lower right) ----
	_draw_block(Rect2(12 * cs, 8 * cs, 6 * cs, 3 * cs), c_civic, c_civic_roof, c_window, c_door, c_outline, cs, "office")

	# ---- PARK / TOWN SQUARE (centre, above horizontal road) ----
	var park := Rect2(8.0 * cs, 1.5 * cs, 2.0 * cs, 2.5 * cs)
	draw_rect(park, c_park)
	draw_rect(park, c_outline, false, 2.0)
	# Park trees (simple circles)
	for td in [[8.4 * cs, 2.1 * cs], [9.6 * cs, 2.1 * cs], [8.4 * cs, 3.4 * cs], [9.6 * cs, 3.4 * cs]]:
		draw_circle(Vector2(td[0], td[1]), 14, Color("2d7a35"))
		draw_circle(Vector2(td[0], td[1]), 14, Color(0,0,0,0.3), false)
	# Bench / fountain
	draw_rect(Rect2(8.7 * cs, 2.65 * cs, 0.6 * cs, 0.4 * cs), Color("c8b468"))
	draw_rect(Rect2(8.7 * cs, 2.65 * cs, 0.6 * cs, 0.4 * cs), c_outline, false, 1.0)

	# ---- Campaign HQ lower centre (below horizontal road) ----
	var hq := Rect2(8.5 * cs, 7.5 * cs, 1.0 * cs, 1.0 * cs)
	draw_rect(hq, c_civic)
	draw_rect(hq, c_civic_roof, false, 2.0)
	# Flag pole
	draw_line(Vector2(8.75 * cs, 7.5 * cs), Vector2(8.75 * cs, 7.1 * cs), c_outline, 2.0)
	draw_rect(Rect2(8.75 * cs, 7.1 * cs, 14, 8), Color("e03030"))

	# ---- GRID overlay (subtle) ----
	for gx in range(width_cells + 1):
		draw_line(Vector2(gx * cs, 0), Vector2(gx * cs, h), Color(0, 0, 0, 0.08), 1.0)
	for gy in range(height_cells + 1):
		draw_line(Vector2(0, gy * cs), Vector2(w, gy * cs), Color(0, 0, 0, 0.08), 1.0)


## Draw a block of buildings inside rect. style = "house" or "office".
func _draw_block(rect: Rect2, wall: Color, roof: Color, win: Color, door: Color,
				outline: Color, cs: float, style: String) -> void:
	draw_rect(rect, wall)
	draw_rect(rect, outline, false, 1.5)

	var bw := cs * 0.72
	var bh := rect.size.y * 0.82
	var count := int(rect.size.x / (bw + 8))
	var spacing := (rect.size.x - count * bw) / maxf(count + 1, 1)

	for i in range(count):
		var bx := rect.position.x + spacing + i * (bw + spacing)
		var by := rect.position.y + rect.size.y - bh
		var building := Rect2(bx, by, bw, bh)

		# Wall
		draw_rect(building, wall)
		# Roof
		if style == "house":
			var pts := PackedVector2Array([
				Vector2(bx - 4, by),
				Vector2(bx + bw * 0.5, by - cs * 0.38),
				Vector2(bx + bw + 4, by)
			])
			draw_colored_polygon(pts, roof)
			draw_polyline(pts, outline, 1.5)
		else:
			draw_rect(Rect2(bx, by, bw, cs * 0.14), roof)
		# Outline
		draw_rect(building, outline, false, 1.5)
		# Windows
		var wr := int(bh / (cs * 0.42))
		for row in range(wr):
			var wy := by + 6 + row * cs * 0.38
			if wy + cs * 0.22 > by + bh - cs * 0.26:
				break
			for col in range(2):
				var wx := bx + 6 + col * (bw * 0.5 - 3)
				draw_rect(Rect2(wx, wy, bw * 0.28, cs * 0.22), win)
				draw_rect(Rect2(wx, wy, bw * 0.28, cs * 0.22), outline, false, 1.0)
		# Door (ground floor only)
		var dx := bx + bw * 0.5 - bw * 0.12
		draw_rect(Rect2(dx, by + bh - cs * 0.36, bw * 0.24, cs * 0.36), door)
		draw_rect(Rect2(dx, by + bh - cs * 0.36, bw * 0.24, cs * 0.36), outline, false, 1.0)
