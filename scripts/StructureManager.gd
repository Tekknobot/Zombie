extends Area2D

@export var structure_type: String
@export var demolished_texture: Texture2D
@onready var Map = $TileMap

var tile_pos

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):	
	var unit_global_position = self.position
	var unit_pos = get_node("../TileMap").local_to_map(unit_global_position)
	get_node("../TileMap").astar_grid.set_point_solid(unit_pos, true)
	
	self.tile_pos = get_node("../TileMap").local_to_map(self.position)
	# Z index layering
	self.z_index = (tile_pos.x + tile_pos.y) + 1
