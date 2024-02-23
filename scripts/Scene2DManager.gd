extends Node2D

const N = 0x1
const E = 0x2
const S = 0x4
const W = 0x8

var cell_walls = {Vector2i(0, -1): N, Vector2i(1, 0): E,
				  Vector2i(0, 1): S, Vector2i(-1, 0): W}

var moves = {N: Vector2i(0, -1),
			 S: Vector2i(0, 1),
			 E: Vector2i(1, 0),
			 W: Vector2i(-1, 0)}
			
@onready var Map = $TileMap
@export var spawn_button : Button

var building = preload("res://scenes/building.scn")
var tower = preload("res://scenes/tower.scn")
var stadium = preload("res://scenes/stadium.scn")
var district = preload("res://scenes/district.scn")

var buildingblank = preload("res://scenes/buildingblank.scn")
var towerblank = preload("res://scenes/towerblank.scn")
var stadiumblank = preload("res://scenes/stadiumblank.scn")
var districtblank = preload("res://scenes/districtblank.scn")

var map_pos = Vector2(0,0)
var road_pos = Vector2(0,0)
var rng = RandomNumberGenerator.new()
var tile_id
var fastNoiseLite = FastNoiseLite.new()
var grid = []

var grid_width = 16
var grid_height = 16

var structures: Array[Area2D]
var structures_blank: Array[Area2D]

var buildings = []
var towers = []
var stadiums = []
var districts = []

var buildingsblank = []
var towersblank = []
var stadiumsblank = []
var districtsblank = []

var world = false
var mars = false
var moon = false

var tile_num = 1
var my_odd_x: int
var my_odd_y: int

var progresscount: int
var biome
var foundation_tile



# Called when the node enters the scene tree for the first time.
func _ready():	
	generate_world()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):	
	pass
	
func _input(event):
	pass														

func move(dir):
	map_pos += moves[dir]
	if map_pos.x >= 0 and map_pos.x <= 15 and map_pos.y >= 0 and map_pos.y <= 15:
		generate_tile(map_pos)
	
func generate_tile(cell):
		var _cells = find_valid_tiles(cell)
		Map.set_cell(0, map_pos, -1, Vector2i(0, 0), 0)
		Map.set_cell(0, map_pos, tile_id, Vector2i(0, 0), 0)		
		
func find_valid_tiles(cell):
	var valid_tiles = []
	# check all possible tiles, 0 - 15
	for i in range(16):
		# check the target space's neighbors (if they exist)
		var is_match = false
		for n in cell_walls.keys():		
			var neighbor_id = Map.get_cell_source_id(0, cell + n, false)
			if neighbor_id >= 0:
				# id == -1 is a blank tile
				if (neighbor_id & cell_walls[-n])/cell_walls[-n] == (i & cell_walls[n])/cell_walls[n]:
					is_match = true
				else:
					is_match = false
					# if we found a mismatch, we don't need to check the remaining sides
					break
		if is_match and not i in valid_tiles:
			valid_tiles.append(i)
	return valid_tiles
	
func generate_world():
	# A random number generator which we will use for the noise seed
	var tilelist = [0, 11, 12, 3, 4, 5]
	
	#var rng = RandomNumberGenerator.new()zz
	fastNoiseLite.seed = rng.randi_range(0, 256)
	fastNoiseLite.TYPE_PERLIN
	fastNoiseLite.fractal_octaves = tilelist.size()
	fastNoiseLite.fractal_gain = 0
	
	for x in grid_width:
		grid.append([])
		await get_tree().create_timer(0).timeout
		for y in grid_height:
			grid[x].append(0)
			# We get the noise coordinate as an absolute value (which represents the gradient - or layer)	
			var absNoise = abs(fastNoiseLite.get_noise_2d(x,y))
			var tiletoplace = int(floor((absNoise * tilelist.size())))
			Map.set_cell(0, Vector2i(x,y), tilelist[tiletoplace], Vector2i(0, 0), 0)	
			progresscount += 1	

	spawn_structures()

func spawn_structures():						
	# Randomize structures at start	
	for i in 64: #buildings
		var my_random_tile_x = rng.randi_range(1, 14)
		var my_random_tile_y = rng.randi_range(1, 14)
		var tile_pos = Vector2i(my_random_tile_x, my_random_tile_y)
		var tile_center_pos = Map.map_to_local(tile_pos) + Vector2(0,0) / 2		
		var buildingblank_inst = buildingblank.instantiate()
		buildingblank_inst.position = tile_center_pos
		add_child(buildingblank_inst)
		buildingblank_inst.add_to_group("buildingsblank")
		buildingblank_inst.add_to_group("structuresblank")		
		buildingblank_inst.z_index = tile_pos.x + tile_pos.y				
		buildingblank_inst.get_child(0).modulate = Color8(rng.randi_range(150, 255), rng.randi_range(150, 255), rng.randi_range(150, 255))		
		buildingblank_inst.position = Vector2(tile_center_pos.x, tile_center_pos.y-500)						
		var tween: Tween = create_tween()
		tween.tween_property(buildingblank_inst, "position", tile_center_pos, 1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)				
		await get_tree().create_timer(0).timeout		
		Map.set_cell(0, Vector2i(my_random_tile_x, my_random_tile_y), 6, Vector2i(0, 0), 0)		
		progresscount += 1
		
	for i in 3: #stadiums
		var my_random_tile_x = rng.randi_range(1, 14)
		var my_random_tile_y = rng.randi_range(1, 14)
		var tile_pos = Vector2i(my_random_tile_x, my_random_tile_y)
		var tile_center_pos = Map.map_to_local(tile_pos) + Vector2(0,0) / 2		
		var stadiumblank_inst = stadiumblank.instantiate()
		stadiumblank_inst.position = tile_center_pos
		add_child(stadiumblank_inst)
		stadiumblank_inst.add_to_group("stadiumsblank")		
		stadiumblank_inst.add_to_group("structuresblank")
		stadiumblank_inst.z_index = tile_pos.x + tile_pos.y				
		stadiumblank_inst.get_child(0).modulate = Color8(rng.randi_range(150, 255), rng.randi_range(150, 255), rng.randi_range(150, 255))		
		stadiumblank_inst.position = Vector2(tile_center_pos.x, tile_center_pos.y-500)						
		var tween: Tween = create_tween()
		tween.tween_property(stadiumblank_inst, "position", tile_center_pos, 1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)				
		await get_tree().create_timer(0).timeout			
		Map.set_cell(0, Vector2i(my_random_tile_x, my_random_tile_y), 7, Vector2i(0, 0), 0)
		progresscount += 1
			
	for i in 3: #districts
		var my_random_tile_x = rng.randi_range(1, 14)
		var my_random_tile_y = rng.randi_range(1, 14)
		var tile_pos = Vector2i(my_random_tile_x, my_random_tile_y)
		var tile_center_pos = Map.map_to_local(tile_pos) + Vector2(0,0) / 2		
		var districtblank_inst = districtblank.instantiate()
		districtblank_inst.position = tile_center_pos
		add_child(districtblank_inst)
		districtblank_inst.add_to_group("districtsblank")	
		districtblank_inst.add_to_group("structuresblank")	
		districtblank_inst.z_index = tile_pos.x + tile_pos.y				
		districtblank_inst.get_child(0).modulate = Color8(rng.randi_range(150, 255), rng.randi_range(150, 255), rng.randi_range(150, 255))		
		districtblank_inst.position = Vector2(tile_center_pos.x, tile_center_pos.y-500)						
		var tween: Tween = create_tween()
		tween.tween_property(districtblank_inst, "position", tile_center_pos, 1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)				
		await get_tree().create_timer(0).timeout		
		Map.set_cell(0, Vector2i(my_random_tile_x, my_random_tile_y), 8, Vector2i(0, 0), 0)
		progresscount += 1

	for i in 3: #towers
		var my_random_tile_x = rng.randi_range(1, 14)
		var my_random_tile_y = rng.randi_range(1, 14)
		Map.set_cell(0, Vector2i(my_random_tile_x, my_random_tile_y), 9, Vector2i(0, 0), 0)
		progresscount += 1			
					
	buildings = get_tree().get_nodes_in_group("buildings")
	towers = get_tree().get_nodes_in_group("towers")
	stadiums = get_tree().get_nodes_in_group("stadiums")
	districts = get_tree().get_nodes_in_group("districts")
	
	buildingsblank = get_tree().get_nodes_in_group("buildingsblank")
	towersblank = get_tree().get_nodes_in_group("towersblank")
	stadiumsblank = get_tree().get_nodes_in_group("stadiumsblank")
	districtsblank = get_tree().get_nodes_in_group("districtsblank")
	
	structures.append_array(buildings)
	structures.append_array(towers)
	structures.append_array(stadiums)
	structures.append_array(districts)	
	
	structures_blank.append_array(buildingsblank)
	structures_blank.append_array(towersblank)
	structures_blank.append_array(stadiumsblank)
	structures_blank.append_array(districtsblank)		
				
	for i in 3: #towersblank
		var my_random_tile_x = rng.randi_range(1, 13)
		var my_random_tile_y = rng.randi_range(1, 13)	
		my_odd_x = my_random_tile_x + ((my_random_tile_x+1)%2 * sign(my_random_tile_x-my_odd_x))	
		my_odd_y = my_random_tile_y + ((my_random_tile_y+1)%2 * sign(my_random_tile_y-my_odd_y))	
		var tile_pos = Vector2i(my_odd_x, my_odd_y)
		var tile_center_pos = Map.map_to_local(tile_pos) + Vector2(0,0) / 2		
		var towerblank_inst = towerblank.instantiate()
		towerblank_inst.position = tile_center_pos
		add_child(towerblank_inst)	
		towerblank_inst.add_to_group("towersblank")	
		towerblank_inst.add_to_group("structuresblank")	
		towerblank_inst.z_index = tile_pos.x + tile_pos.y
		towerblank_inst.get_child(0).modulate = Color8(rng.randi_range(150, 255), rng.randi_range(150, 255), rng.randi_range(150, 255))		
		progresscount += 1
		
	environment_tiles()

func environment_tiles():
	var tile_random_id = rng.randi_range(3, 5)
	# Tiles
	for h in structures_blank.size():
		var structure_group = get_tree().get_nodes_in_group("structuresblank")
		var structure_global_pos = structure_group[h].position
		var structure_pos = Map.local_to_map(structure_global_pos)
		map_pos = structure_pos
		
		for i in tile_num:
			tile_id = tile_random_id
			var size = moves.size()
			var random_key = moves.keys()[randi() % size]					
			move(random_key)
			await get_tree().create_timer(0).timeout
			progresscount += 1
		map_pos = structure_pos
		for i in tile_num:
			tile_id = tile_random_id
			var size = moves.size()
			var random_key = moves.keys()[randi() % size]					
			move(random_key)
			await get_tree().create_timer(0).timeout
			progresscount += 1
		map_pos = structure_pos
		for i in tile_num:
			tile_id = tile_random_id
			var size = moves.size()
			var random_key = moves.keys()[randi() % size]					
			move(random_key)
			await get_tree().create_timer(0).timeout
			progresscount += 1
		map_pos = structure_pos
		for i in tile_num:
			tile_id = tile_random_id
			var size = moves.size()
			var random_key = moves.keys()[randi() % size]					
			move(random_key)	
			await get_tree().create_timer(0).timeout
			progresscount += 1	
			
	await spawn_towersblank()			

func spawn_towersblank():	
	towerblank = get_tree().get_nodes_in_group("towersblank")
	towerblank.append_array(towerblank)				
	generate_roads()

func generate_roads():				
	# Roads		
	for h in 3:
		var structure_group = get_tree().get_nodes_in_group("towersblank")
		var structure_global_pos = structure_group[h].position
		var structure_pos = Map.local_to_map(structure_global_pos)
		map_pos = structure_pos
				
		for i in grid_width:
			tile_id = 42
			move(E)
			await get_tree().create_timer(0).timeout
			progresscount += 1
		map_pos = structure_pos	
		for i in grid_width:
			tile_id = 41
			move(S)
			await get_tree().create_timer(0).timeout
			progresscount += 1
		map_pos = structure_pos
		for i in grid_width:
			tile_id = 42
			move(W)
			await get_tree().create_timer(0).timeout
			progresscount += 1
		map_pos = structure_pos
		for i in grid_width:
			tile_id = 41
			move(N)	
			await get_tree().create_timer(0).timeout
			progresscount += 1
					
		# Intersection		
		for i in grid_width:
			for j in grid_height:
				if Map.get_cell_source_id(0, Vector2i(i,j)) == 41:
					var surrounding_cells = Map.get_surrounding_cells(Vector2i(i,j))
					for k in 4:
						if Map.get_cell_source_id(0, surrounding_cells[0]) == 42 and Map.get_cell_source_id(0, surrounding_cells[1]) == 41 and Map.get_cell_source_id(0, surrounding_cells[2]) == 42 and Map.get_cell_source_id(0, surrounding_cells[3]) == 41:
							Map.set_cell(0, Vector2i(i,j), 43, Vector2i(0, 0), 0)		
							progresscount += 1												
			
		for i in grid_width:
			for j in grid_height:
				if Map.get_cell_source_id(0, Vector2i(i,j)) == 42:
					var surrounding_cells = Map.get_surrounding_cells(Vector2i(i,j))
					for k in 4:
						if Map.get_cell_source_id(0, surrounding_cells[0]) == 42 and Map.get_cell_source_id(0, surrounding_cells[1]) == 41 and Map.get_cell_source_id(0, surrounding_cells[2]) == 42 and Map.get_cell_source_id(0, surrounding_cells[3]) == 41:
							Map.set_cell(0, Vector2i(i,j), 43, Vector2i(0, 0), 0)
							progresscount += 1	

	for i in 3: #towers intresection final
		var tower_pos = Map.local_to_map(towerblank[i].position)
		Map.set_cell(0, tower_pos, 43, Vector2i(0, 0), 0)
														
	spawn_buildings()
		
func spawn_buildings():
	for i in grid_width:
		for j in grid_height:
			if Map.get_cell_source_id(0, Vector2i(i,j)) == 6:	
				var tile_pos = Vector2i(i, j)
				var tile_center_pos = Map.map_to_local(tile_pos) + Vector2(0,0) / 2		
				var building_inst = building.instantiate()
				building_inst.position = tile_center_pos
				add_child(building_inst)
				building_inst.add_to_group("buildings")		
				building_inst.z_index = tile_pos.x + tile_pos.y
				building_inst.get_child(0).modulate = Color8(rng.randi_range(150, 255), rng.randi_range(150, 255), rng.randi_range(150, 255))	
				building_inst.position = Vector2(tile_center_pos.x, tile_center_pos.y-500)						
				var tween: Tween = create_tween()
				tween.tween_property(building_inst, "position", tile_center_pos, 1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)				
				await get_tree().create_timer(0).timeout
				Map.set_cell(0, Vector2i(i, j), 6, Vector2i(0, 0), 0)
				progresscount += 1					

	structures.append_array(buildings)
	structures.append_array(towers)
	structures.append_array(stadiums)
	structures.append_array(districts)
					
	spawn_stadiums()	
				
func spawn_stadiums():
	for i in grid_width:
		for j in grid_height:
			if Map.get_cell_source_id(0, Vector2i(i,j)) == 7:	
				var tile_pos = Vector2i(i, j)
				var tile_center_pos = Map.map_to_local(tile_pos) + Vector2(0,0) / 2		
				var stadium_inst = stadium.instantiate()
				stadium_inst.position = tile_center_pos
				add_child(stadium_inst)	
				stadium_inst.add_to_group("stadiums")	
				stadium_inst.z_index = tile_pos.x + tile_pos.y
				stadium_inst.get_child(0).modulate = Color8(rng.randi_range(150, 255), rng.randi_range(150, 255), rng.randi_range(150, 255))		
				stadium_inst.position = Vector2(tile_center_pos.x, tile_center_pos.y-500)						
				var tween: Tween = create_tween()
				tween.tween_property(stadium_inst, "position", tile_center_pos, 1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)				
				await get_tree().create_timer(0).timeout
				Map.set_cell(0, Vector2i(i, j), 7, Vector2i(0, 0), 0)
				progresscount += 1
				

	structures.append_array(buildings)
	structures.append_array(towers)
	structures.append_array(stadiums)
	structures.append_array(districts)
		
	spawn_districts()
	
func spawn_districts():
	for i in grid_width:
		for j in grid_height:
			if Map.get_cell_source_id(0, Vector2i(i,j)) == 8:		
				var tile_pos = Vector2i(i, j)
				var tile_center_pos = Map.map_to_local(tile_pos) + Vector2(0,0) / 2		
				var district_inst = district.instantiate()
				district_inst.position = tile_center_pos
				add_child(district_inst)
				district_inst.add_to_group("districts")		
				district_inst.z_index = tile_pos.x + tile_pos.y				
				district_inst.get_child(0).modulate = Color8(rng.randi_range(150, 255), rng.randi_range(150, 255), rng.randi_range(150, 255))		
				district_inst.position = Vector2(tile_center_pos.x, tile_center_pos.y-500)						
				var tween: Tween = create_tween()
				tween.tween_property(district_inst, "position", tile_center_pos, 1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)				
				await get_tree().create_timer(0).timeout
				Map.set_cell(0, Vector2i(i, j), 8, Vector2i(0, 0), 0)
				progresscount += 1

	structures.append_array(buildings)
	structures.append_array(towers)
	structures.append_array(stadiums)
	structures.append_array(districts)
	
	spawn_towers_final()
	
func spawn_towers_final():
	for i in grid_width:
		for j in grid_height:
			if Map.get_cell_source_id(0, Vector2i(i,j)) == 9:	
				var my_random_tile_x = rng.randi_range(1, 14)
				var my_random_tile_y = rng.randi_range(1, 14)	
				var tile_pos = Vector2i(my_random_tile_x, my_random_tile_y)
				var tile_center_pos = Map.map_to_local(tile_pos) + Vector2(0,0) / 2		
				var tower_inst = tower.instantiate()
				tower_inst.position = tile_center_pos
				add_child(tower_inst)	
				tower_inst.add_to_group("towers")	
				tower_inst.z_index = tile_pos.x + tile_pos.y
				tower_inst.get_child(0).modulate = Color8(rng.randi_range(150, 255), rng.randi_range(150, 255), rng.randi_range(150, 255))		
				Map.set_cell(0, Vector2i(i, j), 9, Vector2i(0, 0), 0)
				progresscount += 1	
				
	towers = get_tree().get_nodes_in_group("towers")
	structures.append_array(towers)
	spawn_button.show()
	add_to_structures_array()
							
func add_to_structures_array():
	buildings = get_tree().get_nodes_in_group("buildings")
	towers = get_tree().get_nodes_in_group("towers")
	stadiums = get_tree().get_nodes_in_group("stadiums")
	districts = get_tree().get_nodes_in_group("districts")
		
	structures.append_array(buildings)
	structures.append_array(towers)
	structures.append_array(stadiums)
	structures.append_array(districts)
	
	check_duplicates(structures)
	#print(structures.size())

func check_duplicates(a):
	var is_dupe = false
	var found_dupe = false 

	for i in range(a.size()):
		if is_dupe == true:
			break
		for j in range(a.size()):
			if a[j].position == a[i].position:
				#is_dupe = true
				found_dupe = true
				#print("duplicate")
				
				var i_pos = Map.local_to_map(a[i].position)	
				var i_global = Map.map_to_local(Vector2i(i_pos.x, i_pos.y)) + Vector2(0,0) / 2	
				a[i].position = i_global
				var tile_pos_i = Vector2i(i_pos.x, i_pos.y)
				#a[i].get_child(0).modulate = Color8(255, 255, 255)	
				a[j].get_child(0).modulate.a = 0
				a[i].z_index = tile_pos_i.x + tile_pos_i.y
				Map.astar_grid.set_point_solid(i_pos, false)
								
				var j_pos = Map.local_to_map(a[j].position)	
				var j_global = Map.map_to_local(Vector2i(j_pos.x, j_pos.y)) + Vector2(0,0) / 2	
				a[j].position = j_global
				var tile_pos_j = Vector2i(j_pos.x, j_pos.y)
				#a[j].get_child(0).modulate = Color8(0, 0, 0)
				a[j].get_child(0).modulate.a = 1	
				a[j].z_index = tile_pos_j.x + tile_pos_j.y
				Map.astar_grid.set_point_solid(j_pos, true)


		
func _on_reset_button_pressed():
	get_tree().reload_current_scene()
