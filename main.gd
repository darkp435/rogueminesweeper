extends Node

var grid = []
var rng = RandomNumberGenerator.new()
var sprite_texture = load("res://unrevealed.png")
var collision_shape_rect = RectangleShape2D.new()

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

func generate_grid(x: int, y: int, mines: int):
	var mines_list = []
	
	for _i in range(mines):
		var mine = generate_mine(x, y)
		while mine in mines_list:
			mine = generate_mine(x, y)
		mines_list.append(mine)
	
	for _j in range(x):
		var row_to_append = []
		for _k in range(y):
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
			# Position describes the center
			var pos = Vector2(row * 32, col * 32)
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
	collision_shape_rect.size = Vector2(32, 32)
	generate_grid(10, 10, 10)
	draw_grid()

func on_grid(x, y):
	var length = len(grid[0])
	var height = len(grid)
	
	return y > -1 and x > -1 and x < length and y < height

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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_collision_detector_area_entered(area: Area2D) -> void:
	for child in area.get_children():
		if child is Sprite2D:
			child.texture = display_map[reveal(grid_coord_from_name(area.name))]
