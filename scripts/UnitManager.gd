extends Area2D

@export var direction = Vector2.LEFT

var last_position: Vector2
var this_position: Vector2

var pos : Vector2
var old_pos : Vector2
var moving : bool

var moved = false

var tile_pos

@export var unit_name: String
@export var unit_movement: int
@export var unit_type: String
@export var unit_num: int
@export var selected = false
@export var selected_pos: Vector2i

var attacked = false


# Called when the node enters the scene tree for the first time.
func _ready():
	old_pos = global_position;
	pos = global_position;
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#set pos to current position
	pos = global_position;
	if pos - old_pos:
		moving = true;
	else:
		moving = false;
	#create old pos from pos
	old_pos = pos;
		
	# Face towards moving direction
	last_position = this_position
	this_position = self.position

	if this_position.x > last_position.x:
		scale.x = -1
		direction = Vector2.RIGHT
	if this_position.x < last_position.x:
		scale.x = 1	
		direction = Vector2.LEFT
		
	var mouse_pos = get_global_mouse_position()
	mouse_pos.y += 16
	var mouse_local_pos = get_node("../TileMap").local_to_map(mouse_pos)
	self.tile_pos = get_node("../TileMap").local_to_map(self.position)
	
	# Z index layering
	self.z_index = (tile_pos.x + tile_pos.y) + 1
	
	#A star
	if self.is_in_group("dead"):
		pass
	else:
		get_node("../TileMap").astar_grid.set_point_solid(tile_pos, true)	

	if self.moved == true:
		self.modulate = Color8(110, 110, 110)
	else:
		self.modulate = Color8(255, 255, 255)

	
	
	var unit_global_position = self.position
	var unit_pos = get_node("../TileMap").local_to_map(unit_global_position)
	
	# Check if off map
	for i in get_node("../TileMap").all_units.size():
		var unit_center_position = get_node("../TileMap").all_units[i].position
		var unit_position = get_node("../TileMap").local_to_map(unit_center_position)		
		if unit_pos.x < 0 or unit_pos.x > 15 or unit_pos.y < 0 or unit_pos.y > 15:
			self.get_child(0).play("death")
			await get_tree().create_timer(0.5).timeout	
			self.position.y -= 500							
			break

func get_closest_attack_zombies():
	var all_players = get_tree().get_nodes_in_group("zombies")
	var closest_player = null
 
	if (all_players.size() > 0):
		closest_player = all_players[0]
		for player in all_players:
			var distance_to_this_player = global_position.distance_squared_to(player.global_position)	
			var distance_to_closest_player = global_position.distance_squared_to(closest_player.global_position)
			if (distance_to_this_player < distance_to_closest_player):
				closest_player = player
				
	return closest_player

func get_closest_attack_dog():
	var all_players = get_tree().get_nodes_in_group("dogs")
	var closest_player = null
 
	if (all_players.size() > 0):
		closest_player = all_players[0]
		for player in all_players:
			var distance_to_this_player = global_position.distance_squared_to(player.global_position)	
			var distance_to_closest_player = global_position.distance_squared_to(closest_player.global_position)
			if (distance_to_this_player < distance_to_closest_player):
				closest_player = player
				
	return closest_player

func get_closest_attack_humans():
	var all_players = get_tree().get_nodes_in_group("humans")
	var closest_player = null
 
	if (all_players.size() > 0):
		closest_player = all_players[0]
		for player in all_players:
			var distance_to_this_player = global_position.distance_squared_to(player.global_position)	
			var distance_to_closest_player = global_position.distance_squared_to(closest_player.global_position)
			if (distance_to_this_player < distance_to_closest_player):
				closest_player = player
				
	return closest_player
