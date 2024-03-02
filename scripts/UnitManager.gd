extends Area2D

@export var direction = Vector2.LEFT

var last_position: Vector2
var this_position: Vector2

var pos : Vector2
var old_pos : Vector2
var moving : bool

var moved = false

var tile_pos

@export var unit_team: int
@export var unit_name: String
@export var unit_movement: int
@export var unit_attack_range: int
@export var unit_type: String
@export var unit_num: int
@export var selected = false

@onready var root = $"."

var attacked = false
var zombies = []
var humans = []
var all_units = []

var structures: Array[Area2D]
var buildings = []
var towers = []
var stadiums = []
var districts = []

var landmines = []

var only_once = true

var kill_count = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	zombies = get_tree().get_nodes_in_group("zombies")
	humans = get_tree().get_nodes_in_group("humans")
	
	all_units.append_array(zombies)
	all_units.append_array(humans)

	buildings = get_tree().get_nodes_in_group("buildings")
	towers = get_tree().get_nodes_in_group("towers")
	stadiums = get_tree().get_nodes_in_group("stadiums")
	districts = get_tree().get_nodes_in_group("districts")

	structures.append_array(buildings)
	structures.append_array(towers)
	structures.append_array(stadiums)
	structures.append_array(districts)
	
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

	if self.moved == true and self.attacked == true:
		self.modulate = Color8(110, 110, 110)
	else:
		self.modulate = Color8(255, 255, 255)

	if self.kill_count >= 2 and self.unit_type == "Dog":
		self.modulate = Color8(110, 110, 110)
	else:
		self.modulate = Color8(255, 255, 255)

	var unit_global_position = self.position
	var unit_pos = get_node("../TileMap").local_to_map(unit_global_position)
	
	# Check if off map
	for i in get_node("../TileMap").cpu_units.size():
		var unit_center_position = get_node("../TileMap").cpu_units[i].position
		var unit_position = get_node("../TileMap").local_to_map(unit_center_position)		
		if unit_pos.x < 0 or unit_pos.x > 15 or unit_pos.y < 0 or unit_pos.y > 15:
			self.get_child(0).play("death")
			await get_tree().create_timer(0.5).timeout	
			self.position.y -= 500		
			self.add_to_group("dead") 
			self.remove_from_group("zombies") 
			get_node("../TileMap").moving = false
			break

	# Check for unit collisions	
	for i in get_node("../TileMap").cpu_units.size():
		if get_node("../TileMap").cpu_units[i] != self and self.position == get_node("../TileMap").cpu_units[i].position and self.unit_type == "Zombie" and !self.is_in_group("dead"):
			self.get_child(0).play("death")
			await get_tree().create_timer(0.5).timeout	
			self.position.y -= 500		
			self.add_to_group("dead")
			self.remove_from_group("zombies")	
			
			get_node("../TileMap").cpu_units[i].get_child(0).play("death")
			await get_tree().create_timer(0.5).timeout	
			get_node("../TileMap").cpu_units[i].position.y -= 500		
			get_node("../TileMap").cpu_units[i].add_to_group("dead")
			get_node("../TileMap").cpu_units[i].remove_from_group("zombies")	
			get_node("../TileMap").moving = false	
			break

	#Structure collisions			
	for i in structures.size():
		if self.unit_type == "Human":
			return
		var unit_center_pos = get_node("../TileMap").local_to_map(self.position)
		var structure_pos = get_node("../TileMap").local_to_map(structures[i].position)
		if unit_center_pos == structure_pos and get_node("../SpawnManager").spawn_complete == true:
			if only_once == true:
				only_once = false
				self.get_child(0).play("death")
				
				await get_tree().create_timer(0.5).timeout	
				
				self.position.y -= 500	
				self.get_child(0).modulate.a = 0	
				self.add_to_group("dead")
				self.remove_from_group("zombies")

				#await get_tree().create_timer(0).timeout
				
				var explosion = preload("res://scenes/vfx/explosion.scn")
				var explosion_instance = explosion.instantiate()
				var explosion_position = get_node("../TileMap").map_to_local(structure_pos) + Vector2(0,0) / 2
				explosion_instance.set_name("explosion")
				get_parent().add_child(explosion_instance)
				explosion_instance.position = explosion_position	
				explosion_instance.position.y -= 16
				explosion_instance.z_index = (structure_pos.x + structure_pos.y) + 1
				var demo_structure = structures[i]				
				demo_structure.get_child(0).play("demolished")
				demo_structure.get_child(0).modulate = Color8(255, 255, 255) 		
				get_node("../TileMap").moving = false	
			

func landmine_collisions():			
	var unit_center_pos = get_node("../TileMap").local_to_map(self.position)		
	for i in get_node("../TileMap").all_landmines.size():		
		var mine_pos = get_node("../TileMap").local_to_map(get_node("../TileMap").all_landmines[i].position)
		if unit_center_pos == mine_pos and only_once == true:		
			only_once == false		
			var explosion = preload("res://scenes/vfx/explosion.scn")
			var explosion_instance = explosion.instantiate()
			var explosion_position = get_node("../TileMap").map_to_local(mine_pos) + Vector2(0,0) / 2
			explosion_instance.set_name("explosion")
			get_parent().add_child(explosion_instance)
			explosion_instance.position = explosion_position	
			explosion_instance.position.y -= 16
			explosion_instance.z_index = (mine_pos.x + mine_pos.y) + 1
			get_node("../TileMap").all_landmines[i].position.y -= 500
			self.position.y -= 500		
			self.add_to_group("dead")
			self.remove_from_group("zombies")	
			self.get_child(0).play("death")	
			get_node("../TileMap").landmines_total -= 1	
			get_node("../TileMap").moving = false
	
	get_node("../Arrow").hide()
	get_node("../Arrow2").hide()

func structure_collisions():		
	#Structure collisions			
	for i in structures.size():
		var unit_center_pos = get_node("../TileMap").local_to_map(self.position)
		var structure_pos = get_node("../TileMap").local_to_map(get_node("/root/Scene2D").structures[i].position)
		if unit_center_pos == structure_pos and get_node("../SpawnManager").spawn_complete == true:
			self.get_child(0).play("death")
				
			await get_tree().create_timer(0.5).timeout	
			
			self.position.y -= 500		
			self.get_child(0).modulate.a = 0	
			self.add_to_group("dead")
			self.remove_from_group("zombies")

			#await get_tree().create_timer(0).timeout
			
			var explosion = preload("res://scenes/vfx/explosion.scn")
			var explosion_instance = explosion.instantiate()
			var explosion_position = get_node("../TileMap").map_to_local(structure_pos) + Vector2(0,0) / 2
			explosion_instance.set_name("explosion")
			get_parent().add_child(explosion_instance)
			explosion_instance.position = explosion_position	
			explosion_instance.position.y -= 16
			explosion_instance.z_index = (structure_pos.x + structure_pos.y) + 1				
			get_node("/root/Scene2D").structures[i].get_child(0).play("demolished")
			get_node("/root/Scene2D").structures[i].get_child(0).modulate = Color8(255, 255, 255) 		
			get_node("../TileMap").moving = false	

func fuel_dog():
	humans = get_tree().get_nodes_in_group("humans")
	for j in humans.size():
		if get_node("../SpawnManager").spawn_complete == true and self.unit_type == "Dog":
			var surrounding_cells = get_node("../TileMap").get_surrounding_cells(self.tile_pos)	
			for i in surrounding_cells.size():
				if humans[j].tile_pos == surrounding_cells[i]:
					self.modulate = Color8(255, 255, 255)
					self.kill_count = 0
					self.moved == false
					self.attacked == false

func get_closest_attack_zombies():
	var all_players = get_tree().get_nodes_in_group("zombies")
	for i in all_players.size():
		if !all_players[i].is_in_group("dead"):
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


