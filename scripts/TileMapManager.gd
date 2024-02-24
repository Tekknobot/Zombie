extends TileMap

var grid = []
var grid_width = 16
var grid_height = 16

var rng = RandomNumberGenerator.new()

@export var hovertile: Sprite2D
@export var zombie_button: Button
@export var node2D: Node2D
@export var attacks_container: HBoxContainer

@onready var line_2d = $"../Line2D"
@onready var post_a = $"../postA"
@onready var pre_b = $"../preB"
@onready var sprite_2d = $"../Sprite2D"

var projectile = preload("res://scenes/projectiles/projectile.scn")

var astar_grid = AStarGrid2D.new()
var clicked_pos = Vector2i(0,0);

var zombies = []
var dogs = []
var humans = []

var all_units = []
var user_units = []
var cpu_units = []

var selected_pos = Vector2i(0,0);
var target_pos = Vector2i(0,0);
var selected_unit_num = 1

var moving = false
var clicked_zombie = false
var right_clicked_unit
var left_clicked_unit

var left_clicked_unit_position

var only_once = true
var attack_range = false
var landmines_range = false

var landmines = []
var all_landmines = []

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

			clicked_pos = tile_pos	
			
			humans = get_tree().get_nodes_in_group("humans")
			zombies = get_tree().get_nodes_in_group("zombies")
			dogs = get_tree().get_nodes_in_group("dogs")
			
			all_units.append_array(humans)
			all_units.append_array(zombies)
			all_units.append_array(dogs)			
			user_units.append_array(dogs)			
			user_units.append_array(humans)			
			cpu_units.append_array(zombies)
				
			# Ranged Attack
			if only_once:
				for h in all_units.size():					
					var clicked_center_pos = map_to_local(clicked_pos) + Vector2(0,0) / 2
					left_clicked_unit = all_units[h]
					
					#projectile and melee	
					if clicked_center_pos == all_units[h].position and get_cell_source_id(1, tile_pos) == 48 and right_clicked_unit.attacked == false and attack_range == true and landmines_range == false:
						only_once = false
						
						if right_clicked_unit.unit_team == 1:
							right_clicked_unit.attacked = true
							right_clicked_unit.moved = true
						
						var attack_center_pos = map_to_local(clicked_pos) + Vector2(0,0) / 2	
						
						if right_clicked_unit.scale.x == 1 and right_clicked_unit.position.x > attack_center_pos.x:
							right_clicked_unit.scale.x = 1
						
						elif right_clicked_unit.scale.x == -1 and right_clicked_unit.position.x < attack_center_pos.x:
							right_clicked_unit.scale.x = -1	
						
						if right_clicked_unit.scale.x == -1 and right_clicked_unit.position.x > attack_center_pos.x:
							right_clicked_unit.scale.x = 1
						
						elif right_clicked_unit.scale.x == 1 and right_clicked_unit.position.x < attack_center_pos.x:
							right_clicked_unit.scale.x = -1																																					
												
						right_clicked_unit.get_child(0).play("attack")	
						
						await get_tree().create_timer(0.1).timeout
						right_clicked_unit.get_child(0).play("default")		
						
						var _bumpedvector = clicked_pos
						var right_clicked_pos = local_to_map(right_clicked_unit.position)
						
						#get_node("../Camera2D").shake(0.5, 30, 3)
						
						
						await SetLinePoints(line_2d, Vector2(right_clicked_unit.position.x,right_clicked_unit.position.y-16), Vector2(0,0), Vector2(0,0), Vector2(all_units[h].position.x,all_units[h].position.y-16))
						all_units[h].get_child(0).set_offset(Vector2(0,0))
													
						if right_clicked_pos.y < clicked_pos.y and right_clicked_unit.position.x > attack_center_pos.x:	
							var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x, _bumpedvector.y+1)) + Vector2(0,0) / 2
							get_node("../TileMap").all_units[h].position = clicked_pos
							all_units[h].position = tile_center_pos	
							var unit_pos = local_to_map(all_units[h].position)										
							all_units[h].z_index = unit_pos.x + unit_pos.y	
							var tween: Tween = create_tween()
							tween.tween_property(all_units[h], "modulate:v", 1, 0.50).from(5)

						if right_clicked_pos.y > clicked_pos.y and right_clicked_unit.position.x < attack_center_pos.x:								
							var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x, _bumpedvector.y-1)) + Vector2(0,0) / 2
							get_node("../TileMap").all_units[h].position = clicked_pos
							all_units[h].position = tile_center_pos	
							var unit_pos = local_to_map(all_units[h].position)										
							all_units[h].z_index = unit_pos.x + unit_pos.y
							var tween: Tween = create_tween()
							tween.tween_property(all_units[h], "modulate:v", 1, 0.50).from(5)													
	
						if right_clicked_pos.x > clicked_pos.x and right_clicked_unit.position.x > attack_center_pos.x:	
							var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x-1, _bumpedvector.y)) + Vector2(0,0) / 2										
							get_node("../TileMap").all_units[h].position = clicked_pos
							all_units[h].position = tile_center_pos	
							var unit_pos = local_to_map(all_units[h].position)										
							all_units[h].z_index = unit_pos.x + unit_pos.y
							var tween: Tween = create_tween()
							tween.tween_property(all_units[h], "modulate:v", 1, 0.50).from(5)	
						
						if right_clicked_pos.x < clicked_pos.x and right_clicked_unit.position.x < attack_center_pos.x:
							var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x+1, _bumpedvector.y)) + Vector2(0,0) / 2
							get_node("../TileMap").all_units[h].position = clicked_pos
							all_units[h].position = tile_center_pos	
							var unit_pos = local_to_map(all_units[h].position)										
							all_units[h].z_index = unit_pos.x + unit_pos.y		
							var tween: Tween = create_tween()
							tween.tween_property(all_units[h], "modulate:v", 1, 0.50).from(5)
							
						only_once = true
				
					#landmines
					if right_clicked_unit.position == all_units[h].position and get_cell_source_id(1, tile_pos) == 48 and right_clicked_unit.attacked == false and attack_range == false and landmines_range == true:
						only_once = false
						
						#if right_clicked_unit.unit_team == 1:
							#right_clicked_unit.attacked = true
							#right_clicked_unit.moved = true
						
						var attack_center_position = map_to_local(clicked_pos) + Vector2(0,0) / 2	
						
						if right_clicked_unit.scale.x == 1 and right_clicked_unit.position.x > attack_center_position.x:
							right_clicked_unit.scale.x = 1
						
						elif right_clicked_unit.scale.x == -1 and right_clicked_unit.position.x < attack_center_position.x:
							right_clicked_unit.scale.x = -1	
						
						if right_clicked_unit.scale.x == -1 and right_clicked_unit.position.x > attack_center_position.x:
							right_clicked_unit.scale.x = 1
						
						elif right_clicked_unit.scale.x == 1 and right_clicked_unit.position.x < attack_center_position.x:
							right_clicked_unit.scale.x = -1																																					
												
						
						await get_tree().create_timer(0.1).timeout
						right_clicked_unit.get_child(0).play("default")		
						
						var right_clicked_pos = local_to_map(right_clicked_unit.position)
						
						#get_node("../Camera2D").shake(0.5, 30, 3)
													
						if right_clicked_pos.y < clicked_pos.y and right_clicked_unit.position.x > attack_center_position.x:	
							var tile_center_pos = map_to_local(clicked_pos) + Vector2(0,0) / 2
							var landmine = preload("res://scenes/mines/landmine.scn")
							var landmine_instance = landmine.instantiate()
							var landmine_position = get_node("../TileMap").map_to_local(clicked_pos) + Vector2(0,0) / 2
							landmine_instance.set_name("explosion")
							get_parent().add_child(landmine_instance)
							landmine_instance.position = landmine_position	
							landmine_instance.z_index = clicked_pos.x + clicked_pos.y
							landmine_instance.add_to_group("mines")
							landmines = get_tree().get_nodes_in_group("mines")
							all_landmines.append_array(landmines)
							left_clicked_unit.get_child(0).play("default")	
							

						if right_clicked_pos.y > clicked_pos.y and right_clicked_unit.position.x < attack_center_position.x:								
							var tile_center_pos = map_to_local(clicked_pos) + Vector2(0,0) / 2											
							var landmine = preload("res://scenes/mines/landmine.scn")
							var landmine_instance = landmine.instantiate()
							var landmine_position = get_node("../TileMap").map_to_local(clicked_pos) + Vector2(0,0) / 2
							landmine_instance.set_name("explosion")
							get_parent().add_child(landmine_instance)
							landmine_instance.position = landmine_position	
							landmine_instance.z_index = clicked_pos.x + clicked_pos.y
							landmine_instance.add_to_group("mines")
							landmines = get_tree().get_nodes_in_group("mines")
							all_landmines.append_array(landmines)
							left_clicked_unit.get_child(0).play("default")	
								
						if right_clicked_pos.x > clicked_pos.x and right_clicked_unit.position.x > attack_center_position.x:	
							var tile_center_pos = map_to_local(clicked_pos) + Vector2(0,0) / 2											
							var landmine = preload("res://scenes/mines/landmine.scn")
							var landmine_instance = landmine.instantiate()
							var landmine_position = get_node("../TileMap").map_to_local(clicked_pos) + Vector2(0,0) / 2
							landmine_instance.set_name("explosion")
							get_parent().add_child(landmine_instance)
							landmine_instance.position = landmine_position	
							landmine_instance.z_index = clicked_pos.x + clicked_pos.y
							landmine_instance.add_to_group("mines")
							landmines = get_tree().get_nodes_in_group("mines")
							all_landmines.append_array(landmines)
							left_clicked_unit.get_child(0).play("default")	
													
						if right_clicked_pos.x < clicked_pos.x and right_clicked_unit.position.x < attack_center_position.x:
							var tile_center_pos = map_to_local(clicked_pos) + Vector2(0,0) / 2
							var landmine = preload("res://scenes/mines/landmine.scn")
							var landmine_instance = landmine.instantiate()
							var landmine_position = get_node("../TileMap").map_to_local(clicked_pos) + Vector2(0,0) / 2
							landmine_instance.set_name("explosion")
							get_parent().add_child(landmine_instance)
							landmine_instance.position = landmine_position	
							landmine_instance.z_index = clicked_pos.x + clicked_pos.y
							landmine_instance.add_to_group("mines")
							landmines = get_tree().get_nodes_in_group("mines")
							all_landmines.append_array(landmines)
							left_clicked_unit.get_child(0).play("default")	
													
						only_once = true
						
				
			for i in user_units.size():
				if user_units[i].tile_pos == tile_pos:
					selected_unit_num = user_units[i].unit_num
					selected_pos = user_units[i].tile_pos								
					break
					
			for i in all_landmines.size():
				var mine_pos = local_to_map(all_landmines[i].position)				
				if tile_pos == mine_pos:
					return
					
			#Move unit
			if get_cell_source_id(1, tile_pos) == 10 and astar_grid.is_point_solid(tile_pos) == false and user_units[selected_unit_num].selected == true and clicked_zombie == false:
				#Remove hover tiles										
				for j in grid_height:
					for k in grid_width:
						set_cell(1, Vector2i(j,k), -1, Vector2i(0, 0), 0)
										
				target_pos = tile_pos 
				var patharray = astar_grid.get_point_path(selected_pos, target_pos)

				# Find path and set hover cells
				for h in patharray.size():
					set_cell(1, patharray[h], 10, Vector2i(0, 0), 0)	
										
				# Move unit		
				for h in patharray.size():
					user_units[selected_unit_num].get_child(0).play("move")						
					var tile_center_position = map_to_local(patharray[h]) + Vector2(0,0) / 2
					var tween = create_tween()
					tween.tween_property(user_units[selected_unit_num], "position", tile_center_position, 0.25)
					var unit_pos = local_to_map(user_units[selected_unit_num].position)
					user_units[selected_unit_num].z_index = unit_pos.x + unit_pos.y			
					await get_tree().create_timer(0.25).timeout	
					for i in all_landmines.size():
						var mine_pos = local_to_map(all_landmines[i].position)	
						var path_pos = local_to_map(tile_center_position)
						if path_pos	== mine_pos:
							user_units[selected_unit_num].landmine_collisions()	
							# Remove hover cells
							for j in patharray.size():
								set_cell(1, patharray[j], -1, Vector2i(0, 0), 0)
								
							return
				
				# Remove hover cells
				for h in patharray.size():
					set_cell(1, patharray[h], -1, Vector2i(0, 0), 0)				
		
				for i in user_units.size():
					user_units[i].get_child(0).play("default")
					tile_pos = null
					
				for i in user_units.size():	
					var surrounding_cells = get_surrounding_cells(target_pos)
					for k in surrounding_cells.size():
						for j in cpu_units.size():
							var attack_center_pos = local_to_map(cpu_units[j].position)
							var attack_center_position = map_to_local(attack_center_pos) + Vector2(0,0) / 2
							if surrounding_cells[k] == attack_center_pos and !cpu_units[j].is_in_group("dead"):					
								if user_units[selected_unit_num].scale.x == 1 and user_units[selected_unit_num].position.x > attack_center_position.x:
									user_units[selected_unit_num].scale.x = 1
								elif user_units[selected_unit_num].scale.x == -1 and user_units[selected_unit_num].position.x < attack_center_position.x:
									user_units[selected_unit_num].scale.x = -1	
								if user_units[selected_unit_num].scale.x == -1 and user_units[selected_unit_num].position.x > attack_center_position.x:
									user_units[selected_unit_num].scale.x = 1
								elif user_units[selected_unit_num].scale.x == 1 and user_units[selected_unit_num].position.x < attack_center_position.x:
									user_units[selected_unit_num].scale.x = -1						
				
								user_units[selected_unit_num].get_child(0).play("attack")
								var tween: Tween = create_tween()
								tween.tween_property(cpu_units[j], "modulate:v", 1, 0.50).from(5)			
								await get_tree().create_timer(1).timeout
								cpu_units[j].get_child(0).play("death")
								user_units[selected_unit_num].get_child(0).play("default")	
								cpu_units[j].add_to_group("dead")
								cpu_units[j].remove_from_group("zombies")
					
								user_units[selected_unit_num].moved = true
								return						
					
			#Show movement range	
			for i in all_units.size():				
				if all_units[i].unit_type == "Zombie":		
					#Place hover tiles		
					for j in zombies.size():
						var unit_pos = local_to_map(zombies[j].position)
						if unit_pos == tile_pos and attack_range == false:					
							show_zombie_movement_range()
							all_units[i].selected = false
							return
						else:
							all_units[i].selected = false
														
			for i in all_units.size():					
				if all_units[i].unit_type == "Dog" and all_units[i].moved == false:		
					#Place hover tiles		
					for j in dogs.size():
						var unit_pos = local_to_map(dogs[j].position)
						if unit_pos == tile_pos:					
							show_dog_movement_range()	
							all_units[i].selected = true
							clicked_zombie = false
							attack_range = false
							return
						else:
							all_units[i].selected = false
									
			for i in user_units.size():
				if user_units[selected_unit_num].moved == false:
					user_units[i].get_child(0).play("default")					
					#Place hover tiles		
					for j in humans.size():
						var unit_pos = local_to_map(humans[j].position)
						if unit_pos == tile_pos:
							show_humans_movement_range()
							user_units[selected_unit_num].selected = true
							clicked_zombie = false
							attack_range = false
							return	
						else:
							user_units[selected_unit_num].selected = false																		

		if event.button_index == MOUSE_BUTTON_RIGHT:				
			#Remove hover tiles										
			for j in grid_height:
				for k in grid_width:
					set_cell(1, Vector2i(j,k), -1, Vector2i(0, 0), 0)
																			
			var mouse_pos = get_global_mouse_position()
			mouse_pos.y += 8
			var tile_pos = local_to_map(mouse_pos)		
			var tile_data = get_cell_tile_data(0, tile_pos)

			if tile_data is TileData:				
				for i in user_units.size():
					var unit_pos = local_to_map(user_units[i].position)

					if unit_pos == tile_pos:
						attack_range = true
						landmines_range = false
						right_clicked_unit = user_units[i]
						
						var hoverflag_1 = true															
						for j in 16:	
							set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
							if hoverflag_1 == true:
								for k in node2D.structures.size():
									if tile_pos.x-j >= 0:	
										set_cell(1, Vector2i(tile_pos.x-j, tile_pos.y), 48, Vector2i(0, 0), 0)
										if node2D.structures[k].coord == Vector2i(tile_pos.x-j, tile_pos.y):
											hoverflag_1 = false
											set_cell(1, Vector2i(tile_pos.x-j, tile_pos.y), -1, Vector2i(0, 0), 0)	
											break	
								
						var hoverflag_2 = true										
						for j in 16:	
							set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
							if hoverflag_2 == true:											
								for k in node2D.structures.size():																						
									if tile_pos.y+j <= 16:
										set_cell(1, Vector2i(tile_pos.x, tile_pos.y+j), 48, Vector2i(0, 0), 0)
										if node2D.structures[k].coord == Vector2i(tile_pos.x, tile_pos.y+j):
											hoverflag_2 = false
											set_cell(1, Vector2i(tile_pos.x, tile_pos.y+j), -1, Vector2i(0, 0), 0)
											break

						var hoverflag_3 = true	
						for j in 16:	
							set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
							if hoverflag_3 == true:											
								for k in node2D.structures.size():																													
									if tile_pos.x+j <= 16:
										set_cell(1, Vector2i(tile_pos.x+j, tile_pos.y), 48, Vector2i(0, 0), 0)
										if node2D.structures[k].coord == Vector2i(tile_pos.x+j, tile_pos.y):
											hoverflag_3 = false
											set_cell(1, Vector2i(tile_pos.x+j, tile_pos.y), -1, Vector2i(0, 0), 0)
											break

						var hoverflag_4 = true	
						for j in 16:	
							set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
							if hoverflag_4 == true:											
								for k in node2D.structures.size():																											
									if tile_pos.y-j >= 0:									
										set_cell(1, Vector2i(tile_pos.x, tile_pos.y-j), 48, Vector2i(0, 0), 0)
										if node2D.structures[k].coord == Vector2i(tile_pos.x, tile_pos.y-j):
											hoverflag_4 = false
											set_cell(1, Vector2i(tile_pos.x, tile_pos.y-j), -1, Vector2i(0, 0), 0)
											break

					
			if tile_pos.x == 0:
				set_cell(1, Vector2i(tile_pos.x-1, tile_pos.y), -1, Vector2i(0, 0), 0)
			if tile_pos.y == 0:
				set_cell(1, Vector2i(tile_pos.x, tile_pos.y-1), -1, Vector2i(0, 0), 0)							
			if tile_pos.x == 15:
				set_cell(1, Vector2i(tile_pos.x+1, tile_pos.y), -1, Vector2i(0, 0), 0)
			if tile_pos.y == 15:
				set_cell(1, Vector2i(tile_pos.x, tile_pos.y+1), -1, Vector2i(0, 0), 0)	
	
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
					var attack_center_position = map_to_local(attack_center_pos) + Vector2(0,0) / 2		
						
					if dogs[active_dog].scale.x == 1 and dogs[active_dog].position.x > attack_center_position.x:
						dogs[active_dog].scale.x = 1
					elif dogs[active_dog].scale.x == -1 and dogs[active_dog].position.x < attack_center_position.x:
						dogs[active_dog].scale.x = -1	
					if dogs[active_dog].scale.x == -1 and dogs[active_dog].position.x > attack_center_position.x:
						dogs[active_dog].scale.x = 1
					elif dogs[active_dog].scale.x == 1 and dogs[active_dog].position.x < attack_center_position.x:
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
					var attack_center_position = map_to_local(attack_center_pos) + Vector2(0,0) / 2	
								
					if humans[active_humans].scale.x == 1 and humans[active_humans].position.x > attack_center_position.x:
						humans[active_humans].scale.x = 1
					elif humans[active_humans].scale.x == -1 and humans[active_humans].position.x < attack_center_position.x:
						humans[active_humans].scale.x = -1	
					if humans[active_humans].scale.x == -1 and humans[active_humans].position.x > attack_center_position.x:
						humans[active_humans].scale.x = 1
					elif humans[active_humans].scale.x == 1 and humans[active_humans].position.x < attack_center_position.x:
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
	var target_human = rng.randi_range(0,humans.size()-1)			
	if !zombies[active_zombie].is_in_group("dead") and !humans[target_human].is_in_group("dead"):
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
				for i in all_landmines.size():
					var mine_pos = local_to_map(all_landmines[i].position)	
					var path_pos = local_to_map(tile_center_position)
					if path_pos	== mine_pos:
						zombies[active_zombie].landmine_collisions()	
						# Remove hover cells
						for j in patharray.size():
							set_cell(1, patharray[j], -1, Vector2i(0, 0), 0)							
						return				
				if h == zombies[active_zombie].unit_movement:
					break

							
			# Remove hover cells
			for h in patharray.size():
				set_cell(1, patharray[h], -1, Vector2i(0, 0), 0)
			
			zombies[active_zombie].get_child(0).play("default")	
			
			for i in 4:
				var zombies_pos = local_to_map(zombies[active_zombie].position)
				if zombies_pos == zombie_surrounding_cells[i]:
					var attack_center_position = map_to_local(zombie_target_pos) + Vector2(0,0) / 2	
								
					if zombies[active_zombie].scale.x == 1 and zombies[active_zombie].position.x > attack_center_position.x:
						zombies[active_zombie].scale.x = 1
					elif zombies[active_zombie].scale.x == -1 and zombies[active_zombie].position.x < attack_center_position.x:
						zombies[active_zombie].scale.x = -1	
					if zombies[active_zombie].scale.x == -1 and zombies[active_zombie].position.x > attack_center_position.x:
						zombies[active_zombie].scale.x = 1
					elif zombies[active_zombie].scale.x == 1 and zombies[active_zombie].position.x < attack_center_position.x:
						zombies[active_zombie].scale.x = -1						
		

					zombies[active_zombie].get_child(0).play("attack")
					var tween: Tween = create_tween()
					tween.tween_property(closest_atack, "modulate:v", 1, 0.50).from(5)			
					await get_tree().create_timer(1).timeout
					closest_atack.get_child(0).play("death")	
					await get_tree().create_timer(1).timeout
					closest_atack.add_to_group("dead")
					closest_atack.remove_from_group("humans")
					closest_atack.position.y -= 500
					zombies[active_zombie].get_child(0).play("default")	
					break	
			
func _on_zombie_button_pressed():
	zombie_button.hide()
	
	for i in user_units.size():
		modulate = Color8(255, 255, 255)
		user_units[i].moved = false
		user_units[i].attacked = false

	#Remove hover tiles										
	for j in grid_height:
		for k in grid_width:
			set_cell(1, Vector2i(j,k), -1, Vector2i(0, 0), 0)
			
	for i in zombies.size():
		await zombie_attack_ai()
	
	zombie_button.show()
			
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
			
	#Defualt animations
	for i in user_units.size():
		user_units[i].get_child(0).play("default")
	
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
	
	clicked_zombie = true
	attacks_container.hide()
	
func show_humans_movement_range():
	#Remove hover tiles										
	for j in grid_height:
		for k in grid_width:
			set_cell(1, Vector2i(j,k), -1, Vector2i(0, 0), 0)

	for i in user_units.size():
		user_units[i].get_child(0).play("default")
	
	var mouse_pos = get_global_mouse_position()
	mouse_pos.y += 8
	var tile_pos = local_to_map(mouse_pos)	
	var tile_data = get_cell_tile_data(0, tile_pos)
	humans = get_tree().get_nodes_in_group("humans")
	
	#Place hover tiles		
	for i in humans.size():
		var unit_pos = local_to_map(humans[i].position)
		if unit_pos == tile_pos:
			left_clicked_unit_position = humans[i].position
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
	
	attacks_container.show()
	
func show_dog_movement_range():
	#Remove hover tiles										
	for j in grid_height:
		for k in grid_width:
			set_cell(1, Vector2i(j,k), -1, Vector2i(0, 0), 0)

	for i in user_units.size():
		user_units[i].get_child(0).play("default")
	
	var mouse_pos = get_global_mouse_position()
	mouse_pos.y += 8
	var tile_pos = local_to_map(mouse_pos)	
	var tile_data = get_cell_tile_data(0, tile_pos)
	humans = get_tree().get_nodes_in_group("humans")
	
	#Place hover tiles		
	for i in dogs.size():
		var unit_pos = local_to_map(dogs[i].position)
		if unit_pos == tile_pos:
			#Place hover tiles on all tiles										
			for j in grid_height:
				for k in grid_width:
					set_cell(1, Vector2i(j,k), 10, Vector2i(0, 0), 0)
					set_cell(1, unit_pos, -1, Vector2i(0, 0), 0)
					
	attacks_container.hide()				

func SetLinePoints(line: Line2D, a: Vector2, postA: Vector2, preB: Vector2, b: Vector2):
	get_node("../Seeker").show()
	var _a = get_node("../TileMap").local_to_map(a)
	var _b = get_node("../TileMap").local_to_map(b)		
	
	get_node("../Seeker").position = a
	get_node("../Seeker").z_index = get_node("../Seeker").position.x + get_node("../Seeker").position.y
	var tween: Tween = create_tween()
	tween.tween_property(get_node("../Seeker"), "position", b, 1).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)	
	await get_tree().create_timer(1).timeout	

	get_node("../Seeker").hide()		

	var explosion = preload("res://scenes/vfx/explosion.scn")
	var explosion_instance = explosion.instantiate()
	var explosion_position = get_node("../TileMap").map_to_local(_b) + Vector2(0,0) / 2
	explosion_instance.set_name("explosion")
	get_parent().add_child(explosion_instance)
	explosion_instance.position = explosion_position	
	explosion_instance.position.y -= 16
	explosion_instance.z_index = (_b.x + _b.y) + 1

	#Remove hover tiles										
	for j in grid_height:
		for k in grid_width:
			set_cell(1, Vector2i(j,k), -1, Vector2i(0, 0), 0)	

func show_humans_landmine_range():				
	#Remove hover tiles										
	for j in grid_height:
		for k in grid_width:
			set_cell(1, Vector2i(j,k), -1, Vector2i(0, 0), 0)
																	
	var tile_pos = local_to_map(left_clicked_unit_position)		
	var tile_data = get_cell_tile_data(0, tile_pos)

	if tile_data is TileData:			
		for i in user_units.size():
			var unit_pos = local_to_map(user_units[i].position)

			if unit_pos == tile_pos:
				attack_range = true
				right_clicked_unit = user_units[i]
				
				var hoverflag_1 = true															
				for j in 2:	
					set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
					if hoverflag_1 == true:
						for k in node2D.structures.size():
							if tile_pos.x-j >= 0:	
								set_cell(1, Vector2i(tile_pos.x-j, tile_pos.y), 48, Vector2i(0, 0), 0)
								if node2D.structures[k].coord == Vector2i(tile_pos.x-j, tile_pos.y):
									hoverflag_1 = false
									set_cell(1, Vector2i(tile_pos.x-j, tile_pos.y), -1, Vector2i(0, 0), 0)	
									break	
						
				var hoverflag_2 = true										
				for j in 2:	
					set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
					if hoverflag_2 == true:											
						for k in node2D.structures.size():																						
							if tile_pos.y+j <= 16:
								set_cell(1, Vector2i(tile_pos.x, tile_pos.y+j), 48, Vector2i(0, 0), 0)
								if node2D.structures[k].coord == Vector2i(tile_pos.x, tile_pos.y+j):
									hoverflag_2 = false
									set_cell(1, Vector2i(tile_pos.x, tile_pos.y+j), -1, Vector2i(0, 0), 0)
									break

				var hoverflag_3 = true	
				for j in 2:	
					set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
					if hoverflag_3 == true:											
						for k in node2D.structures.size():																													
							if tile_pos.x+j <= 16:
								set_cell(1, Vector2i(tile_pos.x+j, tile_pos.y), 48, Vector2i(0, 0), 0)
								if node2D.structures[k].coord == Vector2i(tile_pos.x+j, tile_pos.y):
									hoverflag_3 = false
									set_cell(1, Vector2i(tile_pos.x+j, tile_pos.y), -1, Vector2i(0, 0), 0)
									break

				var hoverflag_4 = true	
				for j in 2:	
					set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
					if hoverflag_4 == true:											
						for k in node2D.structures.size():																											
							if tile_pos.y-j >= 0:									
								set_cell(1, Vector2i(tile_pos.x, tile_pos.y-j), 48, Vector2i(0, 0), 0)
								if node2D.structures[k].coord == Vector2i(tile_pos.x, tile_pos.y-j):
									hoverflag_4 = false
									set_cell(1, Vector2i(tile_pos.x, tile_pos.y-j), -1, Vector2i(0, 0), 0)
									break

			
	if tile_pos.x == 0:
		set_cell(1, Vector2i(tile_pos.x-1, tile_pos.y), -1, Vector2i(0, 0), 0)
	if tile_pos.y == 0:
		set_cell(1, Vector2i(tile_pos.x, tile_pos.y-1), -1, Vector2i(0, 0), 0)							
	if tile_pos.x == 15:
		set_cell(1, Vector2i(tile_pos.x+1, tile_pos.y), -1, Vector2i(0, 0), 0)
	if tile_pos.y == 15:
		set_cell(1, Vector2i(tile_pos.x, tile_pos.y+1), -1, Vector2i(0, 0), 0)		
	
	landmines_range = true
	attack_range = false
	
func _on_landmine_button_pressed():
	show_humans_landmine_range()
