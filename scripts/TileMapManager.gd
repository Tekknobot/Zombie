extends TileMap

var grid = []
var grid_width = 16
var grid_height = 16

var rng = RandomNumberGenerator.new()

@export var hovertile: Sprite2D

var astar_grid = AStarGrid2D.new()
var zombies = []
var dogs = []
var humans = []

var all_units = []


# Called when the node enters the scene tree for the first time.
func _ready():
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	astar_grid.size = Vector2i(16, 16)
	astar_grid.cell_size = Vector2(1, 1)
	astar_grid.default_compute_heuristic = 1
	astar_grid.diagonal_mode = 1
	astar_grid.update()
	
	# Tile hover
	var mouse_pos = get_global_mouse_position()
	mouse_pos.y += 8
	var tile_pos = local_to_map(mouse_pos)
	var tile_center_pos = map_to_local(tile_pos) + Vector2(0,0) / 2

	var tile_data = get_cell_tile_data(0, tile_pos)

	if tile_data is TileData:					
		hovertile.position = tile_center_pos
		hovertile.z_index = tile_pos.x + tile_pos.y
		#print(tile_pos);	

	#Remove tiles that are off map
	for h in 16:
		for i in 16:
			set_cell(1, Vector2i(-16+h, i), -1, Vector2i(0, 0), 0)
	for h in 16:
		for i in 16:
			set_cell(1, Vector2i(16+h, i), -1, Vector2i(0, 0), 0)
	for h in 16:
		for i in 16:
			set_cell(1, Vector2i(h, -16+i), -1, Vector2i(0, 0), 0)
	for h in 16:
		for i in 16:
			set_cell(1, Vector2i(h, 16+i), -1, Vector2i(0, 0), 0)
	
	#Remove tiles that are on the corner grids off map
	for h in 16:
		for i in 16:
			set_cell(1, Vector2i(-h-1, -i-1), -1, Vector2i(0, 0), 0)
	for h in 16:
		for i in 16:
			set_cell(1, Vector2i(h+16, -i-1), -1, Vector2i(0, 0), 0)
	for h in 16:
		for i in 16:
			set_cell(1, Vector2i(-h-1, i+16), -1, Vector2i(0, 0), 0)
	for h in 16:
		for i in 16:
			set_cell(1, Vector2i(h+16, i+16), -1, Vector2i(0, 0), 0)


func _input(event):
	if event is InputEventMouseButton:			
		if event.button_index == MOUSE_BUTTON_LEFT:	
			var mouse_pos = get_global_mouse_position()
			mouse_pos.y += 8
			var tile_pos = local_to_map(mouse_pos)	
			var tile_data = get_cell_tile_data(0, tile_pos)
			humans = get_tree().get_nodes_in_group("humans")
			zombies = get_tree().get_nodes_in_group("zombies")
			
			all_units.append_array(humans)
			all_units.append_array(zombies)
			
			for i in all_units.size():
				if all_units[i].unit_type == "Human":
					#Place hover tiles		
					for j in humans.size():
						var unit_pos = local_to_map(humans[j].position)
						if unit_pos == tile_pos:
							show_humans_movement_range()
							
				if all_units[i].unit_type == "Zombie":		
					#Place hover tiles		
					for j in zombies.size():
						var unit_pos = local_to_map(zombies[j].position)
						if unit_pos == tile_pos:					
							show_zombie_movement_range()
								


func dog_attack_ai():
	zombies = get_tree().get_nodes_in_group("zombies")
	dogs = get_tree().get_nodes_in_group("dogs")
	var active_dog = rng.randi_range(0,dogs.size()-1)
	var target_zombie = rng.randi_range(0,zombies.size()-1)			
	if !zombies[target_zombie].is_in_group("dead"):
		var closest_atack = dogs[active_dog].get_closest_attack_zombies()										
		var zombie_target_pos = local_to_map(closest_atack.position)
		var zombie_surrounding_cells = get_surrounding_cells(zombie_target_pos)
							
		dogs[active_dog].get_child(0).play("move")
		var open_tile = rng.randi_range(0,3)
		if astar_grid.is_point_solid(zombie_surrounding_cells[open_tile]) == false and get_cell_source_id(0, zombie_surrounding_cells[open_tile]) != -1: 
			var patharray = astar_grid.get_point_path(dogs[active_dog].tile_pos, zombie_surrounding_cells[open_tile])
				
			# Find path and set hover cells
			for h in patharray.size():
				await get_tree().create_timer(0.01).timeout
				set_cell(1, patharray[h], 10, Vector2i(0, 0), 0)
				
			# Move unit		
			for h in patharray.size():
				var tile_center_position = map_to_local(patharray[h]) + Vector2(0,0) / 2
				var tween = create_tween()
				tween.tween_property(dogs[active_dog], "position", tile_center_position, 0.25)
				var unit_pos = local_to_map(dogs[active_dog].position)
				dogs[active_dog].z_index = unit_pos.x + unit_pos.y			
				await get_tree().create_timer(0.25).timeout
			
			# Remove hover cells
			for h in patharray.size():
				set_cell(1, patharray[h], -1, Vector2i(0, 0), 0)
				
			dogs[active_dog].get_child(0).play("default")	
			for i in 4:
				var zombies_pos = local_to_map(dogs[active_dog].position)
				if zombies_pos == zombie_surrounding_cells[i]:
					var attack_center_pos = map_to_local(zombie_target_pos) + Vector2(0,0) / 2
								
					if dogs[active_dog].scale.x == 1 and dogs[active_dog].position.x > attack_center_pos.x:
						dogs[active_dog].scale.x = 1
					elif dogs[active_dog].scale.x == -1 and dogs[active_dog].position.x < attack_center_pos.x:
						dogs[active_dog].scale.x = -1	
					if dogs[active_dog].scale.x == -1 and dogs[active_dog].position.x > attack_center_pos.x:
						dogs[active_dog].scale.x = 1
					elif dogs[active_dog].scale.x == 1 and dogs[active_dog].position.x < attack_center_pos.x:
						dogs[active_dog].scale.x = -1						
	
			dogs[active_dog].get_child(0).play("attack")
			var tween: Tween = create_tween()
			tween.tween_property(closest_atack, "modulate:v", 1, 0.50).from(5)			
			await get_tree().create_timer(1).timeout
			closest_atack.get_child(0).play("death")
			dogs[active_dog].get_child(0).play("default")	
			closest_atack.add_to_group("dead")
			closest_atack.remove_from_group("zombies")
			
func humans_attack_ai():
	zombies = get_tree().get_nodes_in_group("zombies")
	humans = get_tree().get_nodes_in_group("humans")
	var active_humans = rng.randi_range(0,humans.size()-1)
	var target_zombie = rng.randi_range(0,zombies.size()-1)			
	if !zombies[target_zombie].is_in_group("dead"):
		var closest_atack = humans[active_humans].get_closest_attack_zombies()										
		var zombie_target_pos = local_to_map(closest_atack.position)
		var zombie_surrounding_cells = get_surrounding_cells(zombie_target_pos)
		
		humans[active_humans].get_child(0).play("move")
		var open_tile = rng.randi_range(0,3)
		if astar_grid.is_point_solid(zombie_surrounding_cells[open_tile]) == false and get_cell_source_id(0, zombie_surrounding_cells[open_tile]) != -1: 
			var patharray = astar_grid.get_point_path(humans[active_humans].tile_pos, zombie_surrounding_cells[open_tile])
			# Find path and set hover cells
			for h in patharray.size():
				await get_tree().create_timer(0.01).timeout
				set_cell(1, patharray[h], 10, Vector2i(0, 0), 0)
				if h == humans[active_humans].unit_movement:
					get_node("../TileMap").set_cell(1, patharray[h], 18, Vector2i(0, 0), 0)			
									
			# Move unit		
			for h in patharray.size():
				var tile_center_position = map_to_local(patharray[h]) + Vector2(0,0) / 2
				var tween = create_tween()
				tween.tween_property(humans[active_humans], "position", tile_center_position, 0.25)
				var unit_pos = local_to_map(humans[active_humans].position)
				humans[active_humans].z_index = unit_pos.x + unit_pos.y			
				await get_tree().create_timer(0.25).timeout		
				if h == humans[active_humans].unit_movement:
					break								
			
			# Remove hover cells
			for h in patharray.size():
				set_cell(1, patharray[h], -1, Vector2i(0, 0), 0)
				
			humans[active_humans].get_child(0).play("default")	
			for i in 4:
				var zombies_pos = local_to_map(humans[active_humans].position)
				if zombies_pos == zombie_surrounding_cells[i]:
					var attack_center_pos = map_to_local(zombie_target_pos) + Vector2(0,0) / 2
								
					if humans[active_humans].scale.x == 1 and humans[active_humans].position.x > attack_center_pos.x:
						humans[active_humans].scale.x = 1
					elif humans[active_humans].scale.x == -1 and humans[active_humans].position.x < attack_center_pos.x:
						humans[active_humans].scale.x = -1	
					if humans[active_humans].scale.x == -1 and humans[active_humans].position.x > attack_center_pos.x:
						humans[active_humans].scale.x = 1
					elif humans[active_humans].scale.x == 1 and humans[active_humans].position.x < attack_center_pos.x:
						humans[active_humans].scale.x = -1						
		
					humans[active_humans].get_child(0).play("attack")
					var tween: Tween = create_tween()
					tween.tween_property(closest_atack, "modulate:v", 1, 0.50).from(5)			
					await get_tree().create_timer(1).timeout
					closest_atack.get_child(0).play("death")
					humans[active_humans].get_child(0).play("default")	
					closest_atack.add_to_group("dead")
					closest_atack.remove_from_group("zombies")	
					break	
			
func zombie_attack_ai():
	zombies = get_tree().get_nodes_in_group("zombies")
	var active_zombie = rng.randi_range(0,zombies.size()-1)
	var target_zombie = rng.randi_range(0,zombies.size()-1)			
	if !zombies[active_zombie].is_in_group("dead") and !zombies[target_zombie].is_in_group("dead"):
		var closest_atack = zombies[active_zombie].get_closest_attack_humans()										
		var zombie_target_pos = local_to_map(closest_atack.position)
		var zombie_surrounding_cells = get_surrounding_cells(zombie_target_pos)
		
		zombies[active_zombie].get_child(0).play("move")
		var open_tile = rng.randi_range(0,3)
		if astar_grid.is_point_solid(zombie_surrounding_cells[open_tile]) == false and get_cell_source_id(0, zombie_surrounding_cells[open_tile]) != -1: 
			var patharray = astar_grid.get_point_path(zombies[active_zombie].tile_pos, zombie_surrounding_cells[open_tile])
			# Find path and set hover cells
			for h in patharray.size():
				await get_tree().create_timer(0.01).timeout
				set_cell(1, patharray[h], 10, Vector2i(0, 0), 0)
				if h == zombies[active_zombie].unit_movement:
					get_node("../TileMap").set_cell(1, patharray[h], 18, Vector2i(0, 0), 0)			
				
			# Move unit		
			for h in patharray.size():
				var tile_center_position = map_to_local(patharray[h]) + Vector2(0,0) / 2
				var tween = create_tween()
				tween.tween_property(zombies[active_zombie], "position", tile_center_position, 0.25)
				var unit_pos = local_to_map(zombies[active_zombie].position)
				zombies[active_zombie].z_index = unit_pos.x + unit_pos.y			
				await get_tree().create_timer(0.25).timeout
				if h == zombies[active_zombie].unit_movement:
					break		

							
			# Remove hover cells
			for h in patharray.size():
				set_cell(1, patharray[h], -1, Vector2i(0, 0), 0)
			
			zombies[active_zombie].get_child(0).play("default")	
			
			for i in 4:
				var zombies_pos = local_to_map(zombies[active_zombie].position)
				if zombies_pos == zombie_surrounding_cells[i]:
					var attack_center_pos = map_to_local(zombie_target_pos) + Vector2(0,0) / 2
								
					if zombies[active_zombie].scale.x == 1 and zombies[active_zombie].position.x > attack_center_pos.x:
						zombies[active_zombie].scale.x = 1
					elif zombies[active_zombie].scale.x == -1 and zombies[active_zombie].position.x < attack_center_pos.x:
						zombies[active_zombie].scale.x = -1	
					if zombies[active_zombie].scale.x == -1 and zombies[active_zombie].position.x > attack_center_pos.x:
						zombies[active_zombie].scale.x = 1
					elif zombies[active_zombie].scale.x == 1 and zombies[active_zombie].position.x < attack_center_pos.x:
						zombies[active_zombie].scale.x = -1						
		

					zombies[active_zombie].get_child(0).play("attack")
					var tween: Tween = create_tween()
					tween.tween_property(closest_atack, "modulate:v", 1, 0.50).from(5)			
					await get_tree().create_timer(1).timeout
					closest_atack.get_child(0).play("death")	
					await get_tree().create_timer(1).timeout
					closest_atack.add_to_group("dead")
					closest_atack.remove_from_group("zombies")
					zombies[active_zombie].get_child(0).play("default")	
					break	
			
func _on_zombie_button_pressed():
	zombie_attack_ai()
	#Remove hover tiles										
	for j in grid_height:
		for k in grid_width:
			set_cell(1, Vector2i(j,k), -1, Vector2i(0, 0), 0)
			
func _on_dog_button_pressed():
	dog_attack_ai()
	#Remove hover tiles										
	for j in grid_height:
		for k in grid_width:
			set_cell(1, Vector2i(j,k), -1, Vector2i(0, 0), 0)
				
func _on_soldier_button_pressed():
	humans_attack_ai()	
	#Remove hover tiles										
	for j in grid_height:
		for k in grid_width:
			set_cell(1, Vector2i(j,k), -1, Vector2i(0, 0), 0)
			
func show_zombie_movement_range():
	#Remove hover tiles										
	for j in grid_height:
		for k in grid_width:
			set_cell(1, Vector2i(j,k), -1, Vector2i(0, 0), 0)
	
	var mouse_pos = get_global_mouse_position()
	mouse_pos.y += 8
	var tile_pos = local_to_map(mouse_pos)	
	var tile_data = get_cell_tile_data(0, tile_pos)
	zombies = get_tree().get_nodes_in_group("zombies")
	
	#Place hover tiles		
	for i in zombies.size():
		var unit_pos = local_to_map(zombies[i].position)
		if unit_pos == tile_pos:
			for j in zombies[i].unit_movement:
				
				var surrounding_cells = get_node("../TileMap").get_surrounding_cells(unit_pos)
				
				if zombies[i].unit_movement == 1:
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)
						if surrounding_cells[k].x <= -1 or surrounding_cells[k].y >= 16 or surrounding_cells[k].x >= 16 or surrounding_cells[k].y <= -1:
							set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
							set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y), -1, Vector2i(0, 0), 0)										
				
				if zombies[i].unit_movement == 2:
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)										
						if surrounding_cells[k].x <= -1 or surrounding_cells[k].y >= 16 or surrounding_cells[k].x >= 16 or surrounding_cells[k].y <= -1:
							set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
							set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y), -1, Vector2i(0, 0), 0)								
					for k in surrounding_cells.size():
						set_cell(1, Vector2i(surrounding_cells[k].x+1, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x-1, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)															
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+1), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-1), 10, Vector2i(0, 0), 0)									
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)	
				
				if zombies[i].unit_movement == 3:
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)									
						if surrounding_cells[k].x <= -1 or surrounding_cells[k].y >= 16 or surrounding_cells[k].x >= 16 or surrounding_cells[k].y <= -1:
							set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
							set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y), -1, Vector2i(0, 0), 0)								
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x+1, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x-1, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)															
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+1), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-1), 10, Vector2i(0, 0), 0)								
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x+2, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x-2, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)															
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+2), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-2), 10, Vector2i(0, 0), 0)						

				if zombies[i].unit_movement == 4:
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)									
						if surrounding_cells[k].x <= -1 or surrounding_cells[k].y >= 16 or surrounding_cells[k].x >= 16 or surrounding_cells[k].y <= -1:
							set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
							set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y), -1, Vector2i(0, 0), 0)								
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x+1, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x-1, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)															
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+1), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-1), 10, Vector2i(0, 0), 0)								
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x+2, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x-2, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)															
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+2), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-2), 10, Vector2i(0, 0), 0)															
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x+3, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x-3, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)															
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+3), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-3), 10, Vector2i(0, 0), 0)	
						
					set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
					set_cell(1, Vector2i(unit_pos.x+2, unit_pos.y+2), 10, Vector2i(0, 0), 0)																																								
					set_cell(1, Vector2i(unit_pos.x-2, unit_pos.y-2), 10, Vector2i(0, 0), 0)															
					set_cell(1, Vector2i(unit_pos.x+2, unit_pos.y-2), 10, Vector2i(0, 0), 0)																																								
					set_cell(1, Vector2i(unit_pos.x-2, unit_pos.y+2), 10, Vector2i(0, 0), 0)			

				if zombies[i].unit_movement == 5:
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)									
						if surrounding_cells[k].x <= -1 or surrounding_cells[k].y >= 16 or surrounding_cells[k].x >= 16 or surrounding_cells[k].y <= -1:
							set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
							set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y), -1, Vector2i(0, 0), 0)								
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x+1, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x-1, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)															
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+1), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-1), 10, Vector2i(0, 0), 0)								
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x+2, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x-2, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)															
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+2), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-2), 10, Vector2i(0, 0), 0)															
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x+3, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x-3, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)															
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+3), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-3), 10, Vector2i(0, 0), 0)	
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x+4, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x-4, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)															
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+4), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-4), 10, Vector2i(0, 0), 0)	
															
					set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
					set_cell(1, Vector2i(unit_pos.x+2, unit_pos.y+2), 10, Vector2i(0, 0), 0)																																								
					set_cell(1, Vector2i(unit_pos.x-2, unit_pos.y-2), 10, Vector2i(0, 0), 0)															
					set_cell(1, Vector2i(unit_pos.x+2, unit_pos.y-2), 10, Vector2i(0, 0), 0)																																								
					set_cell(1, Vector2i(unit_pos.x-2, unit_pos.y+2), 10, Vector2i(0, 0), 0)	

					set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
					set_cell(1, Vector2i(unit_pos.x+2, unit_pos.y+3), 10, Vector2i(0, 0), 0)																																								
					set_cell(1, Vector2i(unit_pos.x-3, unit_pos.y-2), 10, Vector2i(0, 0), 0)															
					set_cell(1, Vector2i(unit_pos.x+2, unit_pos.y-3), 10, Vector2i(0, 0), 0)																																								
					set_cell(1, Vector2i(unit_pos.x-3, unit_pos.y+2), 10, Vector2i(0, 0), 0)	

					set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
					set_cell(1, Vector2i(unit_pos.x+3, unit_pos.y+2), 10, Vector2i(0, 0), 0)																																								
					set_cell(1, Vector2i(unit_pos.x-2, unit_pos.y-3), 10, Vector2i(0, 0), 0)															
					set_cell(1, Vector2i(unit_pos.x+3, unit_pos.y-2), 10, Vector2i(0, 0), 0)																																								
					set_cell(1, Vector2i(unit_pos.x-2, unit_pos.y+3), 10, Vector2i(0, 0), 0)				

func show_humans_movement_range():
	#Remove hover tiles										
	for j in grid_height:
		for k in grid_width:
			set_cell(1, Vector2i(j,k), -1, Vector2i(0, 0), 0)
	
	var mouse_pos = get_global_mouse_position()
	mouse_pos.y += 8
	var tile_pos = local_to_map(mouse_pos)	
	var tile_data = get_cell_tile_data(0, tile_pos)
	humans = get_tree().get_nodes_in_group("humans")
	
	#Place hover tiles		
	for i in humans.size():
		var unit_pos = local_to_map(humans[i].position)
		if unit_pos == tile_pos:
			for j in humans[i].unit_movement:
				
				var surrounding_cells = get_node("../TileMap").get_surrounding_cells(unit_pos)
				
				if humans[i].unit_movement == 1:
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)
						if surrounding_cells[k].x <= -1 or surrounding_cells[k].y >= 16 or surrounding_cells[k].x >= 16 or surrounding_cells[k].y <= -1:
							set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
							set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y), -1, Vector2i(0, 0), 0)										
				
				if humans[i].unit_movement == 2:
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)										
						if surrounding_cells[k].x <= -1 or surrounding_cells[k].y >= 16 or surrounding_cells[k].x >= 16 or surrounding_cells[k].y <= -1:
							set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
							set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y), -1, Vector2i(0, 0), 0)								
					for k in surrounding_cells.size():
						set_cell(1, Vector2i(surrounding_cells[k].x+1, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x-1, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)															
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+1), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-1), 10, Vector2i(0, 0), 0)									
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)	
				
				if humans[i].unit_movement == 3:
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)									
						if surrounding_cells[k].x <= -1 or surrounding_cells[k].y >= 16 or surrounding_cells[k].x >= 16 or surrounding_cells[k].y <= -1:
							set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
							set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y), -1, Vector2i(0, 0), 0)								
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x+1, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x-1, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)															
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+1), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-1), 10, Vector2i(0, 0), 0)								
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x+2, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x-2, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)															
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+2), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-2), 10, Vector2i(0, 0), 0)						

				if humans[i].unit_movement == 4:
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)									
						if surrounding_cells[k].x <= -1 or surrounding_cells[k].y >= 16 or surrounding_cells[k].x >= 16 or surrounding_cells[k].y <= -1:
							set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
							set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y), -1, Vector2i(0, 0), 0)								
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x+1, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x-1, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)															
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+1), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-1), 10, Vector2i(0, 0), 0)								
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x+2, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x-2, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)															
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+2), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-2), 10, Vector2i(0, 0), 0)															
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x+3, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x-3, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)															
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+3), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-3), 10, Vector2i(0, 0), 0)	
						
					set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
					set_cell(1, Vector2i(unit_pos.x+2, unit_pos.y+2), 10, Vector2i(0, 0), 0)																																								
					set_cell(1, Vector2i(unit_pos.x-2, unit_pos.y-2), 10, Vector2i(0, 0), 0)															
					set_cell(1, Vector2i(unit_pos.x+2, unit_pos.y-2), 10, Vector2i(0, 0), 0)																																								
					set_cell(1, Vector2i(unit_pos.x-2, unit_pos.y+2), 10, Vector2i(0, 0), 0)			

				if humans[i].unit_movement == 5:
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)									
						if surrounding_cells[k].x <= -1 or surrounding_cells[k].y >= 16 or surrounding_cells[k].x >= 16 or surrounding_cells[k].y <= -1:
							set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
							set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y), -1, Vector2i(0, 0), 0)								
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x+1, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x-1, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)															
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+1), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-1), 10, Vector2i(0, 0), 0)								
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x+2, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x-2, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)															
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+2), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-2), 10, Vector2i(0, 0), 0)															
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x+3, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x-3, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)															
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+3), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-3), 10, Vector2i(0, 0), 0)	
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x+4, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x-4, surrounding_cells[k].y), 10, Vector2i(0, 0), 0)															
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+4), 10, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-4), 10, Vector2i(0, 0), 0)	
															
					set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
					set_cell(1, Vector2i(unit_pos.x+2, unit_pos.y+2), 10, Vector2i(0, 0), 0)																																								
					set_cell(1, Vector2i(unit_pos.x-2, unit_pos.y-2), 10, Vector2i(0, 0), 0)															
					set_cell(1, Vector2i(unit_pos.x+2, unit_pos.y-2), 10, Vector2i(0, 0), 0)																																								
					set_cell(1, Vector2i(unit_pos.x-2, unit_pos.y+2), 10, Vector2i(0, 0), 0)	

					set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
					set_cell(1, Vector2i(unit_pos.x+2, unit_pos.y+3), 10, Vector2i(0, 0), 0)																																								
					set_cell(1, Vector2i(unit_pos.x-3, unit_pos.y-2), 10, Vector2i(0, 0), 0)															
					set_cell(1, Vector2i(unit_pos.x+2, unit_pos.y-3), 10, Vector2i(0, 0), 0)																																								
					set_cell(1, Vector2i(unit_pos.x-3, unit_pos.y+2), 10, Vector2i(0, 0), 0)	

					set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
					set_cell(1, Vector2i(unit_pos.x+3, unit_pos.y+2), 10, Vector2i(0, 0), 0)																																								
					set_cell(1, Vector2i(unit_pos.x-2, unit_pos.y-3), 10, Vector2i(0, 0), 0)															
					set_cell(1, Vector2i(unit_pos.x+3, unit_pos.y-2), 10, Vector2i(0, 0), 0)																																								
					set_cell(1, Vector2i(unit_pos.x-2, unit_pos.y+3), 10, Vector2i(0, 0), 0)				
