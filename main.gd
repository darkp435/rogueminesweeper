extends Node

var grid = []
var rng = RandomNumberGenerator.new()
var sprite_texture = preload("res://unrevealed.png")
var flag_texture = preload("res://flag.png")
var collision_shape_rect = RectangleShape2D.new()
var lives = 3
var revealed = 0
const game_over_scene = preload("res://Scenes/game_over.tscn")
var grid_mines = 10
var grid_x = 10
var grid_y = 10
var level = 1
var flag = false
var flagged_tiles = []

enum SquareState {
	Safe,
	Mine
}

# NOTE: this class may be moved to separate script in future.
class SimpleGridCoord extends RefCounted:
	var x: int
	var y: int
	
	func _init(ix: int, iy: int):
		self.x = ix
		self.y = iy
	
	func equal(other: SimpleGridCoord):
		return self.x == other.x and self.y == other.y

func get_node_from_coord(coord: SimpleGridCoord):
	var path = "%d-%d" % [coord.y, coord.x]
	return get_node(path)

func grid_coord_from_name(grid_name: String):
	var unpacked = grid_name.split("-")
	return SimpleGridCoord.new(int(unpacked[1]), int(unpacked[0]))

func generate_mine(x: int, y: int):
	var mine_x = rng.randi_range(0, x - 1)
	var mine_y = rng.randi_range(0, y - 1)
	return SimpleGridCoord.new(mine_x, mine_y)

func has_coord(list, coord_to_check: SimpleGridCoord):
	for coord in list:
		if coord_to_check.equal(coord):
			return true
	return false

func generate_grid(x: int, y: int, mines: int):
	grid = []
	var mines_list = []
	
	for _i in range(mines):
		var mine = generate_mine(x, y)
		while has_coord(mines_list, mine):
			mine = generate_mine(x, y)
		mines_list.append(mine)
	
	for _j in range(y):
		var row_to_append = []
		for _k in range(x):
			row_to_append.append(SquareState.Safe)
		grid.append(row_to_append)
		
	for mine in mines_list:
		grid[mine.y][mine.x] = SquareState.Mine

func draw_grid():
	for row in range(len(grid)):
		for col in range(len(grid[0])):
			var area = Area2D.new()
			var sprite = Sprite2D.new()
			var collision_shape = CollisionShape2D.new()
			# Sprite is 32 pixels
			area.add_child(sprite)
			area.add_child(collision_shape)
			sprite.texture = sprite_texture
			collision_shape.shape = collision_shape_rect
			area.name = "%d-%d" % [row, col]
			area.set_meta("revealed", false)
			# Position describes the center
			var pos = Vector2(col * 32, row * 32)
			#sprite.position = Vector2(row * 32, col * 32)
			area.position = pos
			self.add_child(area)

const grid_offsets = [
	[0, 1], [0, -1],
	[-1, 0], [-1, 1], [-1, -1],
	[1, 0], [1, -1], [1, 1]
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#if not FileAccess.file_exists("res://2025 Introduction to Organic Chemistry.pptx"):
		#OS.crash("FILE NOT FOUND")
	collision_shape_rect.size = Vector2(32, 32)
	#$CharacterBody2D.position = Vector2(32 * 5, 32 * 10)
	generate_grid(grid_x, grid_y, grid_mines)
	redraw_remaining_label()
	draw_grid()

func on_grid(x, y):
	var length = len(grid[0])
	var height = len(grid)
	
	return y > -1 and x > -1 and x < length and y < height

func destroy_grid():
	for child in self.get_children():
		if "-" in child.name:
			child.queue_free()

func redraw_remaining_label():
	$CanvasLayer/Control/Remaining.text = "Tiles revealed: %d/%d" % [revealed, grid_x * grid_y - grid_mines]

func next_level():
	$CharacterBody2D.position = Vector2(99999999, 0)
	level += 1
	flagged_tiles = []
	destroy_grid()
	#await get_tree().create_timer(2.5).timeout
	$CanvasLayer/Control/Level.text = "Level " + str(level)
	# Either width or height gets increased, randomly
	if rng.randi_range(1, 2) == 1:
		grid_x += 1
	else:
		grid_y += 1
	
	grid_mines += rng.randi_range(1, 5)
	generate_grid(grid_x, grid_y, grid_mines)
	# Delay for queue_free
	await get_tree().create_timer(0.1).timeout
	draw_grid()
	redraw_remaining_label()
	revealed = 0
	$CharacterBody2D.position = Vector2(0, 0)

func reveal(grid_coord: SimpleGridCoord):
	var x = grid_coord.x
	var y = grid_coord.y
	var tile = grid[grid_coord.y][grid_coord.x]
	
	if tile == SquareState.Mine:
		# The tile is a mine
		return -1
	
	var mines_around = 0
	for offset in grid_offsets:
		if on_grid(x + offset[1], y + offset[0]) and grid[y + offset[0]][x + offset[1]] == SquareState.Mine:
			mines_around += 1
	
	return mines_around

var display_map = {
	# Swirl is the mine
	-1: load("res://swirl.png"),
	0: load("res://none.png"),
	1: load("res://one.png"),
	2: load("res://two.png"),
	3: load("res://three.png"),
	4: load("res://four.png"),
	5: load("res://five.png"),
	6: load("res://six.png"),
	7: load("res://seven.png"),
	8: load("res://eight.png")
}

const MINE = -1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("flag"):
		flag = not flag
		if flag:
			$CanvasLayer/Control/RevealMode.texture = flag_texture
		else:
			$CanvasLayer/Control/RevealMode.texture = sprite_texture

func _on_collision_detector_area_entered(area: Area2D) -> void:
	var child = area.get_child(0)
	if not child is Sprite2D or area.get_meta("revealed") or (not flag and area.name in flagged_tiles):
		return
	if len(area.name.split("-")) != 2:
		print("Not a valid name ", area.name)
		return
	var coord = grid_coord_from_name(area.name)
	
	if flag:
		if area.name in flagged_tiles:
			flagged_tiles.erase(area.name)
			child.texture = sprite_texture
		else:
			flagged_tiles.append(area.name)
			child.texture = flag_texture
		return
		
	var result = reveal(coord)
	if result == MINE:
		lives -= 1
		if lives == 0:
			var new_scene = game_over_scene.instantiate()
			$CanvasLayer.add_child(new_scene)
			$CharacterBody2D.speed = 0
			$CharacterBody2D/Sprite2D.visible = false
			
		$CanvasLayer/Control/Lives.text = str(lives)
	else:
		revealed += 1
		redraw_remaining_label()
		
	child.texture = display_map[result]
	area.set_meta("revealed", true)
	
	if revealed == grid_x * grid_y - grid_mines:
		call_deferred("next_level")
