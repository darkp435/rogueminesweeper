extends Node

var grid = []
var rng = RandomNumberGenerator.new()
var sprite_texture = load("res://unrevealed.png")
var collision_shape = RectangleShape2D.new()

enum SquareState {
	Safe,
	Mine
}

class SimpleGridCoord extends RefCounted:
	var x: int
	var y: int
	
	func _init(x: int, y: int):
		self.x = x
		self.y = y
	
	func equal(other: SimpleGridCoord):
		return self.x == other.x and self.y == other.y

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
			collision_shape.shape = collision_shape
			collision_shape.name = "%d-%d" % [row, col]
			# Position describes the center
			sprite.position = Vector2(row * 32, col * 32)
			self.add_child(area)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	collision_shape.size = Vector2(32, 32)
	generate_grid(10, 10, 10)
	draw_grid()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_area_2d_body_entered(body: Node2D) -> void:
	print("Entered!")
