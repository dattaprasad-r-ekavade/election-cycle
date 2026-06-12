class_name TownGenerator
extends RefCounted

## Seeded, theme-aware town generator.
## Produces a grid layout (tiles, buildings, props, collision) that the
## Pokemon-style renderer (town_map_art.gd) draws and town.gd plays in.
## Same seed + theme = same town. Different district = different town.

# Tile IDs
const T_GRASS := 0
const T_GRASS_DARK := 1
const T_TUFT := 2        # tall grass tufts (walkable, rustles)
const T_FLOWER_A := 3
const T_FLOWER_B := 4
const T_PATH := 5
const T_ROAD := 6
const T_SIDEWALK := 7
const T_PLAZA := 8
const T_WATER := 9
const T_SAND := 10
const T_TREE := 11
const T_FENCE := 12
const T_BUILDING := 13   # covered by building rects; never visible directly

const WIDTH := 30
const HEIGHT := 19

## Theme style table. Keys are lowercase style ids.
const THEME_STYLES := {
	"suburban":   {"flowers": 0.05, "tufts": 0.05, "trees": 22, "pond": 0.4, "fences": true,  "landmark": "HOA Office",        "landmark_kind": "civic"},
	"hometown":   {"flowers": 0.07, "tufts": 0.06, "trees": 26, "pond": 0.6, "fences": true,  "landmark": "Mom's House",       "landmark_kind": "house"},
	"university": {"flowers": 0.04, "tufts": 0.04, "trees": 20, "pond": 0.3, "fences": false, "landmark": "Frat House",        "landmark_kind": "commercial"},
	"industrial": {"flowers": 0.01, "tufts": 0.08, "trees": 10, "pond": 0.2, "fences": false, "landmark": "The Old Factory",   "landmark_kind": "factory"},
	"coastal":    {"flowers": 0.04, "tufts": 0.03, "trees": 14, "pond": 0.0, "fences": false, "landmark": "Bait & Ballots",    "landmark_kind": "commercial"},
	"tourist":    {"flowers": 0.06, "tufts": 0.02, "trees": 16, "pond": 0.0, "fences": false, "landmark": "Gift Shoppe #47",   "landmark_kind": "commercial"},
	"downtown":   {"flowers": 0.01, "tufts": 0.02, "trees": 8,  "pond": 0.0, "fences": false, "landmark": "Parking Authority", "landmark_kind": "civic"},
	"rural":      {"flowers": 0.05, "tufts": 0.10, "trees": 24, "pond": 0.8, "fences": true,  "landmark": "The Big Barn",      "landmark_kind": "barn"},
	"tech":       {"flowers": 0.02, "tufts": 0.02, "trees": 12, "pond": 0.3, "fences": false, "landmark": "Drone Depot",       "landmark_kind": "tech"},
	"dream":      {"flowers": 0.12, "tufts": 0.08, "trees": 18, "pond": 0.9, "fences": false, "landmark": "Your Old School???", "landmark_kind": "weird"},
	"crime":      {"flowers": 0.00, "tufts": 0.03, "trees": 9,  "pond": 0.0, "fences": false, "landmark": "Totally Legal Imports", "landmark_kind": "factory"},
	"national":   {"flowers": 0.06, "tufts": 0.02, "trees": 18, "pond": 0.4, "fences": false, "landmark": "Media Tent City",   "landmark_kind": "civic"},
	"capital":    {"flowers": 0.05, "tufts": 0.01, "trees": 16, "pond": 0.5, "fences": false, "landmark": "The Monument",      "landmark_kind": "monument"},
}

## Map a GameManager district_theme to a style id.
static func style_for_theme(theme: String) -> String:
	var t := theme.to_lower().strip_edges()
	if THEME_STYLES.has(t):
		return t
	match t:
		"downtown": return "downtown"
		"coastal": return "coastal"
		_:
			pass
	return "suburban"


static func generate(seed_value: int, style_id: String) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value

	if not THEME_STYLES.has(style_id):
		style_id = "suburban"
	var style: Dictionary = THEME_STYLES[style_id]

	var town := {
		"width": WIDTH,
		"height": HEIGHT,
		"style": style_id,
		"tiles": [],
		"blocked": {},          # Vector2i -> true
		"buildings": [],        # {id, name, kind, rect: Rect2i, door: Vector2i}
		"props": [],            # {kind, cell, blocked}
		"spawn": Vector2i(2, 2),
		"npc_spawns": [],
		"square_rect": Rect2i(),
		"stage_cell": Vector2i(),
	}

	# --- Base grass with variation ---
	var tiles: Array = []
	for y in range(HEIGHT):
		var row: Array = []
		for x in range(WIDTH):
			row.append(T_GRASS if rng.randf() > 0.22 else T_GRASS_DARK)
		tiles.append(row)
	town.tiles = tiles

	# --- Water edge for coastal-ish styles ---
	var water_rows := 0
	if style_id in ["coastal", "tourist"]:
		water_rows = 2
		for y in range(HEIGHT - water_rows, HEIGHT):
			for x in range(WIDTH):
				tiles[y][x] = T_WATER
		for x in range(WIDTH):
			tiles[HEIGHT - water_rows - 1][x] = T_SAND

	var usable_h := HEIGHT - water_rows - (1 if water_rows > 0 else 0)

	# --- Roads (cross layout, position varies by seed) ---
	var road_y := rng.randi_range(7, maxi(7, mini(10, usable_h - 8)))
	var road_x := rng.randi_range(12, 16)
	for x in range(WIDTH):
		tiles[road_y][x] = T_ROAD
		tiles[road_y + 1][x] = T_ROAD
		if road_y - 1 >= 0:
			tiles[road_y - 1][x] = T_SIDEWALK
		if road_y + 2 < usable_h:
			tiles[road_y + 2][x] = T_SIDEWALK
	for y in range(usable_h):
		tiles[y][road_x] = T_ROAD
		tiles[y][road_x + 1] = T_ROAD
		if road_x - 1 >= 0 and tiles[y][road_x - 1] != T_ROAD:
			tiles[y][road_x - 1] = T_SIDEWALK
		if road_x + 2 < WIDTH and tiles[y][road_x + 2] != T_ROAD:
			tiles[y][road_x + 2] = T_SIDEWALK
	# Fix intersection corners back to road
	for y in [road_y, road_y + 1]:
		for x in [road_x, road_x + 1]:
			tiles[y][x] = T_ROAD

	town["road_y"] = road_y
	town["road_x"] = road_x

	# --- Quadrant rects (inside the border, outside roads/sidewalks) ---
	var q_nw := Rect2i(1, 1, road_x - 3, road_y - 3)
	var q_ne := Rect2i(road_x + 3, 1, WIDTH - road_x - 4, road_y - 3)
	var q_sw := Rect2i(1, road_y + 3, road_x - 3, usable_h - road_y - 4)
	var q_se := Rect2i(road_x + 3, road_y + 3, WIDTH - road_x - 4, usable_h - road_y - 4)
	var quads := [q_nw, q_ne, q_sw, q_se]

	# --- Town square: pick the biggest quadrant ---
	var sq_quad_idx := 0
	var best_area := 0
	for i in range(quads.size()):
		var a: int = quads[i].size.x * quads[i].size.y
		if a > best_area:
			best_area = a
			sq_quad_idx = i
	var sq_quad: Rect2i = quads[sq_quad_idx]
	var sq_w: int = mini(6, sq_quad.size.x)
	var sq_h: int = mini(4, sq_quad.size.y)
	# Hug the corner closest to the intersection
	var sq_x: int = sq_quad.position.x if sq_quad.position.x > road_x else sq_quad.position.x + sq_quad.size.x - sq_w
	var sq_y: int = sq_quad.position.y if sq_quad.position.y > road_y else sq_quad.position.y + sq_quad.size.y - sq_h
	var square := Rect2i(sq_x, sq_y, sq_w, sq_h)
	town.square_rect = square
	for y in range(square.position.y, square.end.y):
		for x in range(square.position.x, square.end.x):
			tiles[y][x] = T_PLAZA

	# Fountain in square center, stage at square top
	var fountain := Vector2i(square.position.x + sq_w / 2, square.position.y + sq_h / 2)
	_add_prop(town, "fountain", fountain, true)
	var stage := Vector2i(square.position.x + sq_w / 2 - 1, square.position.y)
	_add_prop(town, "stage", stage, true)
	_add_prop(town, "stage", stage + Vector2i(1, 0), true)
	town.stage_cell = stage
	_add_prop(town, "bench", square.position + Vector2i(0, sq_h - 1), true)
	_add_prop(town, "bench", Vector2i(square.end.x - 1, square.end.y - 1), true)

	# --- Buildings ---
	var occupied: Array = [square]
	# Neighborhood = quadrant opposite the square
	var hood_quad: Rect2i = quads[3 - sq_quad_idx]
	var other_quads: Array = []
	for i in range(quads.size()):
		if i != sq_quad_idx and i != 3 - sq_quad_idx:
			other_quads.append(quads[i])

	# Houses in the neighborhood quadrant
	var house_names := [
		"The Hendersons'", "Chez Mildred", "The Yelling House",
		"Unit 4B (a whole house)", "The Lawn People", "Casa de Votes",
	]
	var house_order := _det_shuffle(house_names, rng)
	var houses_placed := 0
	var max_houses := 3 if hood_quad.size.x < 11 else 4
	var attempts := 0
	while houses_placed < max_houses and attempts < 200:
		attempts += 1
		var hw := 3
		var hh := 3
		var hx := rng.randi_range(hood_quad.position.x, maxi(hood_quad.position.x, hood_quad.end.x - hw))
		var hy := rng.randi_range(hood_quad.position.y, maxi(hood_quad.position.y, hood_quad.end.y - hh))
		var r := Rect2i(hx, hy, hw, hh)
		if not _fits(r, hood_quad) or _overlaps(r.grow(1), occupied):
			continue
		var house_id := "house_%d" % houses_placed
		_place_building(town, tiles, house_id, house_order[houses_placed % house_order.size()], "house", r, rng)
		occupied.append(r)
		houses_placed += 1

	# Core civic buildings spread across remaining quads (and square quad edges)
	var core := [
		{"id": "hq",         "name": "Campaign HQ",  "kind": "hq",         "w": 4, "h": 3},
		{"id": "town_hall",  "name": "Town Hall",    "kind": "civic",      "w": 5, "h": 4},
		{"id": "print_shop", "name": "Print Shop",   "kind": "commercial", "w": 4, "h": 3},
		{"id": "diner",      "name": "Greasy Spoon Diner", "kind": "diner", "w": 4, "h": 3},
		{"id": "landmark",   "name": style.landmark, "kind": style.landmark_kind, "w": 4, "h": 3},
	]
	var placement_quads: Array = other_quads.duplicate()
	placement_quads.append(sq_quad)
	placement_quads.append(hood_quad)
	var qi := 0
	for b in core:
		var bw := int(b.w)
		var bh := int(b.h)
		var placed := false
		# Try progressively smaller footprints if the town is cramped.
		while not placed and bw >= 3 and bh >= 3:
			var tries := 0
			while not placed and tries < 300:
				tries += 1
				var quad: Rect2i = placement_quads[(qi + tries) % placement_quads.size()]
				if quad.size.x < bw or quad.size.y < bh:
					continue
				var bx := rng.randi_range(quad.position.x, quad.end.x - bw)
				var by := rng.randi_range(quad.position.y, maxi(quad.position.y, quad.end.y - bh))
				var r := Rect2i(bx, by, bw, bh)
				if not _fits(r, Rect2i(1, 1, WIDTH - 2, usable_h - 2)) or _overlaps(r.grow(1), occupied):
					continue
				_place_building(town, tiles, b.id, b.name, b.kind, r, rng)
				occupied.append(r)
				placed = true
			if not placed:
				# Fallback: scan whole map for first open grassy slot.
				# Buildings may touch here (row houses are very town-core).
				for y in range(1, usable_h - bh):
					for x in range(1, WIDTH - bw - 1):
						var r2 := Rect2i(x, y, bw, bh)
						if _overlaps(r2, occupied) or not _area_is_grass(tiles, r2):
							continue
						var door2 := Vector2i(r2.position.x + r2.size.x / 2, r2.end.y)
						var door_blocked := false
						for o in occupied:
							if (o as Rect2i).has_point(door2):
								door_blocked = true
								break
						if door_blocked:
							continue
						_place_building(town, tiles, b.id, b.name, b.kind, r2, rng)
						occupied.append(r2)
						placed = true
						break
					if placed:
						break
			if not placed:
				bw -= 1
				bh = maxi(3, bh - 1)
		qi += 1

	# --- Paths from each door to nearest sidewalk/road ---
	for b in town.buildings:
		_carve_path(tiles, b.door, road_x, road_y, usable_h)

	# --- Pond ---
	if rng.randf() < float(style.pond):
		var pond_placed := false
		var ptries := 0
		while not pond_placed and ptries < 80:
			ptries += 1
			var px := rng.randi_range(2, WIDTH - 6)
			var py := rng.randi_range(2, usable_h - 5)
			var pr := Rect2i(px, py, rng.randi_range(3, 4), rng.randi_range(2, 3))
			if _overlaps(pr.grow(1), occupied) or not _area_is_grass(tiles, pr.grow(1)):
				continue
			for y in range(pr.position.y, pr.end.y):
				for x in range(pr.position.x, pr.end.x):
					tiles[y][x] = T_WATER
			occupied.append(pr.grow(1))
			_add_prop(town, "duck_sign", Vector2i(pr.position.x, pr.end.y), false)
			pond_placed = true

	# --- Fences around the neighborhood (suburbs love fences) ---
	if bool(style.fences):
		for b in town.buildings:
			if b.kind != "house":
				continue
			var fr: Rect2i = b.rect.grow(1)
			for x in range(fr.position.x, fr.end.x):
				for y in [fr.position.y, fr.end.y - 1]:
					if _in_bounds(x, y, usable_h) and tiles[y][x] in [T_GRASS, T_GRASS_DARK] and Vector2i(x, y) != b.door + Vector2i(0, 0):
						if rng.randf() < 0.7 and Vector2i(x, y).distance_to(Vector2(b.door)) > 1.2:
							tiles[y][x] = T_FENCE

	# --- Trees: border ring + scattered clusters ---
	for x in range(WIDTH):
		for y in [0, usable_h - 1]:
			if water_rows > 0 and y >= HEIGHT - water_rows - 1:
				continue
			if tiles[y][x] in [T_GRASS, T_GRASS_DARK] and rng.randf() < 0.85:
				tiles[y][x] = T_TREE
	for y in range(usable_h):
		for x in [0, WIDTH - 1]:
			if tiles[y][x] in [T_GRASS, T_GRASS_DARK] and rng.randf() < 0.85:
				tiles[y][x] = T_TREE
	var tree_budget := int(style.trees)
	var ttries := 0
	while tree_budget > 0 and ttries < 400:
		ttries += 1
		var tx := rng.randi_range(1, WIDTH - 2)
		var ty := rng.randi_range(1, usable_h - 2)
		if tiles[ty][tx] in [T_GRASS, T_GRASS_DARK] and not _near_door(town, Vector2i(tx, ty)):
			tiles[ty][tx] = T_TREE
			tree_budget -= 1

	# --- Flowers and tufts ---
	for y in range(usable_h):
		for x in range(WIDTH):
			if tiles[y][x] in [T_GRASS, T_GRASS_DARK]:
				var roll := rng.randf()
				if roll < float(style.flowers):
					tiles[y][x] = T_FLOWER_A if rng.randf() < 0.5 else T_FLOWER_B
				elif roll < float(style.flowers) + float(style.tufts):
					tiles[y][x] = T_TUFT

	# --- Ambient props ---
	_scatter_prop(town, tiles, rng, "lamppost", 4, usable_h)
	_scatter_prop(town, tiles, rng, "trash_can", 2, usable_h)
	_scatter_prop(town, tiles, rng, "mailbox", 2, usable_h)
	if style_id == "industrial" or style_id == "crime":
		_scatter_prop(town, tiles, rng, "barrel", 3, usable_h)
	if style_id == "tech":
		_scatter_prop(town, tiles, rng, "server_box", 3, usable_h)
	if style_id in ["capital", "national"]:
		_add_prop(town, "statue", fountain + Vector2i(2, 0), true)

	# --- Collision map ---
	var blocked: Dictionary = {}
	for y in range(HEIGHT):
		for x in range(WIDTH):
			if tiles[y][x] in [T_TREE, T_WATER, T_FENCE, T_BUILDING]:
				blocked[Vector2i(x, y)] = true
	for p in town.props:
		if bool(p.blocked):
			blocked[p.cell] = true
	town.blocked = blocked

	# --- Spawn: just below HQ door ---
	var hq_b := get_building(town, "hq")
	if not hq_b.is_empty():
		town.spawn = _free_near(town, hq_b.door, usable_h)
	else:
		town.spawn = _free_near(town, Vector2i(road_x, road_y + 2), usable_h)

	# --- NPC spawn cells (walkable, spread out) ---
	var spawn_tries := 0
	while town.npc_spawns.size() < 8 and spawn_tries < 300:
		spawn_tries += 1
		var c := Vector2i(rng.randi_range(2, WIDTH - 3), rng.randi_range(2, usable_h - 2))
		if not blocked.has(c) and c != town.spawn:
			town.npc_spawns.append(c)

	return town


static func get_building(town: Dictionary, id: String) -> Dictionary:
	for b in town.buildings:
		if b.id == id:
			return b
	return {}


static func is_walkable(town: Dictionary, cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= int(town.width) or cell.y >= int(town.height):
		return false
	return not (town.blocked as Dictionary).has(cell)


# ---------- internals ----------

static func _place_building(town: Dictionary, tiles: Array, id: String, bname: String, kind: String, rect: Rect2i, rng: RandomNumberGenerator) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			tiles[y][x] = T_BUILDING
	var door := Vector2i(rect.position.x + rect.size.x / 2, rect.end.y)
	if door.y < tiles.size() and tiles[door.y][door.x] in [T_GRASS, T_GRASS_DARK, T_TUFT, T_FLOWER_A, T_FLOWER_B]:
		tiles[door.y][door.x] = T_PATH
	town.buildings.append({
		"id": id, "name": bname, "kind": kind, "rect": rect, "door": door,
		"variant": rng.randi_range(0, 2),
	})


static func _carve_path(tiles: Array, door: Vector2i, _road_x: int, _road_y: int, usable_h: int) -> void:
	# Doors face south; carve a short walkway downward until we meet
	# pavement or anything we shouldn't bulldoze.
	var y := door.y
	var guard := 0
	while y >= 0 and y < usable_h and guard < 6:
		guard += 1
		var t: int = tiles[y][door.x]
		if t in [T_SIDEWALK, T_ROAD, T_PLAZA, T_PATH] and y != door.y:
			break
		if t in [T_GRASS, T_GRASS_DARK, T_TUFT, T_FLOWER_A, T_FLOWER_B]:
			tiles[y][door.x] = T_PATH
		elif y != door.y:
			break  # never carve through trees, fences, water, or buildings
		y += 1


static func _fits(r: Rect2i, bounds: Rect2i) -> bool:
	return bounds.encloses(r)


static func _overlaps(r: Rect2i, occupied: Array) -> bool:
	for o in occupied:
		if r.intersects(o):
			return true
	return false


static func _area_is_grass(tiles: Array, r: Rect2i) -> bool:
	for y in range(maxi(0, r.position.y), mini(tiles.size(), r.end.y)):
		for x in range(maxi(0, r.position.x), mini((tiles[0] as Array).size(), r.end.x)):
			if not (tiles[y][x] in [T_GRASS, T_GRASS_DARK, T_TUFT, T_FLOWER_A, T_FLOWER_B]):
				return false
	return true


static func _in_bounds(x: int, y: int, usable_h: int) -> bool:
	return x >= 0 and y >= 0 and x < WIDTH and y < usable_h


static func _near_door(town: Dictionary, cell: Vector2i) -> bool:
	for b in town.buildings:
		if Vector2(b.door).distance_to(Vector2(cell)) < 2.0:
			return true
	return false


static func _free_near(town: Dictionary, target: Vector2i, usable_h: int) -> Vector2i:
	for radius in range(0, 8):
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var c := target + Vector2i(dx, dy)
				if c.x >= 1 and c.y >= 1 and c.x < WIDTH - 1 and c.y < usable_h - 1:
					if is_walkable(town, c):
						return c
	return Vector2i(2, 2)


static func _add_prop(town: Dictionary, kind: String, cell: Vector2i, is_blocked: bool) -> void:
	town.props.append({"kind": kind, "cell": cell, "blocked": is_blocked})


static func _scatter_prop(town: Dictionary, tiles: Array, rng: RandomNumberGenerator, kind: String, count: int, usable_h: int) -> void:
	var placed := 0
	var tries := 0
	while placed < count and tries < 120:
		tries += 1
		var c := Vector2i(rng.randi_range(2, WIDTH - 3), rng.randi_range(2, usable_h - 3))
		var t: int = tiles[c.y][c.x]
		if t in [T_GRASS, T_GRASS_DARK, T_SIDEWALK] and not _near_door(town, c):
			var dup := false
			for p in town.props:
				if p.cell == c:
					dup = true
					break
			if dup:
				continue
			_add_prop(town, kind, c, true)
			placed += 1


static func _det_shuffle(arr: Array, rng: RandomNumberGenerator) -> Array:
	var a := arr.duplicate()
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp
	return a
