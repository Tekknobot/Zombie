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

@onready var next_button = $"../Control/MenuContainer/NextButton"
@onready var reset_button = $"../Control/MenuContainer/ResetButton"
@onready var mines_button = $"../Control/AttacksContainer/LandmineButton"
@onready var dog_mines_button = $"../Control/AttacksContainer/DogmineButton"

@onready var laser = $"../Laser"

@onready var soundstream = $"../SoundStream"
@onready var musicstream = $"../MapMusicStream"

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
var only_once_zombie = true
var attack_range = false
var landmines_range = false
var dogmine_range = false
var dog_range = false

var landmines = []
var all_landmines = []
var path_interupted = false
var landmines_total = 0

var structure_interupterd = false

var dead_zombies = []
var dead_humans = []
var get_append_only_once = true
var map_cleared = false

var landmine_once = true
var landmine_temp

var laser_a = Vector2(0,0)
var laser_b = Vector2(0,0)

var swarm_turns = 0
var swarming = false

var random = []
var random_once = true
var index = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	if get_node("../SpawnManager").spawn_complete == true:
		zombies = get_tree().get_nodes_in_group("zombies")
	
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
	
	if get_node("../SpawnManager").spawn_complete == true and moving == true:
		get_node("../Arrow").hide()
		get_node("../Arrow2").hide()
		hovertile.hide()				
						
func _input(event):
	if event is InputEventKey:	
		if event.pressed and event.keycode == KEY_ESCAPE:
			get_tree().quit()
				
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and get_node("../SpawnManager").spawn_complete == true and moving == false and swarming == false:	
			if event.pressed:
				hovertile.show()
				
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
				
				if get_append_only_once:
					get_append_only_once = false
					cpu_units.append_array(zombies)
											
				# Ranged Attack
				for h in all_units.size():					
					var clicked_center_pos = map_to_local(clicked_pos) + Vector2(0,0) / 2
					left_clicked_unit = all_units[h]
					
					#Projectile shoot	
					if clicked_center_pos == all_units[h].position and all_units[h].unit_team != 1 and get_cell_source_id(1, tile_pos) == 48 and right_clicked_unit.attacked == false and attack_range == true and landmines_range == false and right_clicked_unit.unit_name == "Butch":
						
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
						
						soundstream.stream = soundstream.map_sfx[7]
						soundstream.play()	
												
						await get_tree().create_timer(0.1).timeout
						right_clicked_unit.get_child(0).play("default")		
						
						var _bumpedvector = clicked_pos
						var right_clicked_pos = local_to_map(right_clicked_unit.position)
						
						#get_node("../Camera2D").shake(0.5, 30, 3)
						laser_a = Vector2(right_clicked_unit.position.x,right_clicked_unit.position.y-16)
						laser_b = Vector2(all_units[h].position.x,all_units[h].position.y-16)
						 	
						await SetLinePoints(line_2d, Vector2(right_clicked_unit.position.x,right_clicked_unit.position.y-16), Vector2(all_units[h].position.x,all_units[h].position.y-16))
						all_units[h].get_child(0).set_offset(Vector2(0,0))
													
						if right_clicked_pos.y < clicked_pos.y and right_clicked_unit.position.x > attack_center_pos.x:	
							var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x, _bumpedvector.y+1)) + Vector2(0,0) / 2
							get_node("../TileMap").all_units[h].position = clicked_pos
							all_units[h].position = tile_center_pos	
							var unit_pos = local_to_map(all_units[h].position)										
							all_units[h].z_index = unit_pos.x + unit_pos.y	
							var tween: Tween = create_tween()
							tween.tween_property(all_units[h], "modulate:v", 1, 0.50).from(5)
							all_units[h].get_child(0).play("death")
							await get_tree().create_timer(0.5).timeout	
							all_units[h].position.y -= 500		
							all_units[h].add_to_group("dead") 
							all_units[h].remove_from_group("zombies") 	
							soundstream.stream = soundstream.map_sfx[5]
							soundstream.play()															

						if right_clicked_pos.y > clicked_pos.y and right_clicked_unit.position.x < attack_center_pos.x:								
							var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x, _bumpedvector.y-1)) + Vector2(0,0) / 2
							get_node("../TileMap").all_units[h].position = clicked_pos
							all_units[h].position = tile_center_pos	
							var unit_pos = local_to_map(all_units[h].position)										
							all_units[h].z_index = unit_pos.x + unit_pos.y
							var tween: Tween = create_tween()
							tween.tween_property(all_units[h], "modulate:v", 1, 0.50).from(5)
							all_units[h].get_child(0).play("death")
							await get_tree().create_timer(0.5).timeout	
							all_units[h].position.y -= 500		
							all_units[h].add_to_group("dead") 
							all_units[h].remove_from_group("zombies") 																				
							soundstream.stream = soundstream.map_sfx[5]
							soundstream.play()		
							
						if right_clicked_pos.x > clicked_pos.x and right_clicked_unit.position.x > attack_center_pos.x:	
							var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x-1, _bumpedvector.y)) + Vector2(0,0) / 2										
							get_node("../TileMap").all_units[h].position = clicked_pos
							all_units[h].position = tile_center_pos	
							var unit_pos = local_to_map(all_units[h].position)										
							all_units[h].z_index = unit_pos.x + unit_pos.y
							var tween: Tween = create_tween()
							tween.tween_property(all_units[h], "modulate:v", 1, 0.50).from(5)
							all_units[h].get_child(0).play("death")
							await get_tree().create_timer(0.5).timeout	
							all_units[h].position.y -= 500		
							all_units[h].add_to_group("dead") 
							all_units[h].remove_from_group("zombies") 								
							soundstream.stream = soundstream.map_sfx[5]
							soundstream.play()		
													
						if right_clicked_pos.x < clicked_pos.x and right_clicked_unit.position.x < attack_center_pos.x:
							var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x+1, _bumpedvector.y)) + Vector2(0,0) / 2
							get_node("../TileMap").all_units[h].position = clicked_pos
							all_units[h].position = tile_center_pos	
							var unit_pos = local_to_map(all_units[h].position)										
							all_units[h].z_index = unit_pos.x + unit_pos.y		
							var tween: Tween = create_tween()
							tween.tween_property(all_units[h], "modulate:v", 1, 0.50).from(5)
							all_units[h].get_child(0).play("death")
							await get_tree().create_timer(0.5).timeout	
							all_units[h].position.y -= 500		
							all_units[h].add_to_group("dead") 
							all_units[h].remove_from_group("zombies") 							
							soundstream.stream = soundstream.map_sfx[5]
							soundstream.play()		
													
						get_node("../Arrow").hide()
						get_node("../Arrow2").hide()
						
						await get_tree().create_timer(1).timeout
						_on_zombie()	

					#Dog orbital laser
					if clicked_center_pos == all_units[h].position and all_units[h].unit_team != 1 and get_cell_source_id(1, tile_pos) == 48 and right_clicked_unit.unit_type == "Dog" and right_clicked_unit.unit_name == "Robodog" and right_clicked_unit.unit_name == "Robodog":
						
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
						
						soundstream.stream = soundstream.map_sfx[3]
						soundstream.play()	
												
						await get_tree().create_timer(0.1).timeout
						right_clicked_unit.get_child(0).play("default")		
						
						var _bumpedvector = clicked_pos
						var right_clicked_pos = local_to_map(right_clicked_unit.position)
						
						#get_node("../Camera2D").shake(0.5, 30, 3)
						
						laser_a = Vector2(right_clicked_unit.position.x,right_clicked_unit.position.y-16)
						laser_b = Vector2(all_units[h].position.x,all_units[h].position.y-16)

						get_node("../Arrow").hide()
						get_node("../Arrow2").hide()
							
						await laser.draw_laser()
						all_units[h].get_child(0).set_offset(Vector2(0,0))
													
						if right_clicked_pos.y < clicked_pos.y and right_clicked_unit.position.x > attack_center_pos.x:	
							var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x, _bumpedvector.y+1)) + Vector2(0,0) / 2
							get_node("../TileMap").all_units[h].position = clicked_pos
							all_units[h].position = tile_center_pos	
							var unit_pos = local_to_map(all_units[h].position)										
							all_units[h].z_index = unit_pos.x + unit_pos.y	
							var tween: Tween = create_tween()
							tween.tween_property(all_units[h], "modulate:v", 1, 0.50).from(5)
							all_units[h].get_child(0).play("death")
							await get_tree().create_timer(0.5).timeout	
							all_units[h].position.y -= 500		
							all_units[h].add_to_group("dead") 
							all_units[h].remove_from_group("zombies") 								
							soundstream.stream = soundstream.map_sfx[5]
							soundstream.play()		
							
						if right_clicked_pos.y > clicked_pos.y and right_clicked_unit.position.x < attack_center_pos.x:								
							var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x, _bumpedvector.y-1)) + Vector2(0,0) / 2
							get_node("../TileMap").all_units[h].position = clicked_pos
							all_units[h].position = tile_center_pos	
							var unit_pos = local_to_map(all_units[h].position)										
							all_units[h].z_index = unit_pos.x + unit_pos.y
							var tween: Tween = create_tween()
							tween.tween_property(all_units[h], "modulate:v", 1, 0.50).from(5)	
							all_units[h].get_child(0).play("death")
							await get_tree().create_timer(0.5).timeout	
							all_units[h].position.y -= 500		
							all_units[h].add_to_group("dead") 
							all_units[h].remove_from_group("zombies") 																				
							soundstream.stream = soundstream.map_sfx[5]
							soundstream.play()		
							
						if right_clicked_pos.x > clicked_pos.x and right_clicked_unit.position.x > attack_center_pos.x:	
							var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x-1, _bumpedvector.y)) + Vector2(0,0) / 2										
							get_node("../TileMap").all_units[h].position = clicked_pos
							all_units[h].position = tile_center_pos	
							var unit_pos = local_to_map(all_units[h].position)										
							all_units[h].z_index = unit_pos.x + unit_pos.y
							var tween: Tween = create_tween()
							tween.tween_property(all_units[h], "modulate:v", 1, 0.50).from(5)	
							all_units[h].get_child(0).play("death")
							await get_tree().create_timer(0.5).timeout	
							all_units[h].position.y -= 500		
							all_units[h].add_to_group("dead") 
							all_units[h].remove_from_group("zombies") 		
							soundstream.stream = soundstream.map_sfx[5]
							soundstream.play()		
																				
						if right_clicked_pos.x < clicked_pos.x and right_clicked_unit.position.x < attack_center_pos.x:
							var tile_center_pos = map_to_local(Vector2i(_bumpedvector.x+1, _bumpedvector.y)) + Vector2(0,0) / 2
							get_node("../TileMap").all_units[h].position = clicked_pos
							all_units[h].position = tile_center_pos	
							var unit_pos = local_to_map(all_units[h].position)										
							all_units[h].z_index = unit_pos.x + unit_pos.y		
							var tween: Tween = create_tween()
							tween.tween_property(all_units[h], "modulate:v", 1, 0.50).from(5)
							all_units[h].get_child(0).play("death")
							await get_tree().create_timer(0.5).timeout	
							all_units[h].position.y -= 500		
							all_units[h].add_to_group("dead") 
							all_units[h].remove_from_group("zombies") 								
							soundstream.stream = soundstream.map_sfx[5]
							soundstream.play()		
						
						get_node("../Arrow").hide()
						get_node("../Arrow2").hide()	

						#Remove hover tiles										
						for j in grid_height:
							for k in grid_width:
								set_cell(1, Vector2i(j,k), -1, Vector2i(0, 0), 0)	
													
						await get_tree().create_timer(1).timeout
						_on_zombie()	

					#Projectile drop
					if clicked_center_pos == all_units[h].position and get_cell_source_id(1, tile_pos) == 48 and right_clicked_unit.unit_type == "Human" and right_clicked_unit.unit_name == "Snake" and user_units[selected_unit_num].unit_name != "Robodog" and left_clicked_unit.unit_name != "Butch" and left_clicked_unit.unit_name != "Robodog":
						right_clicked_unit.get_child(0).play("attack")	
						
						soundstream.stream = soundstream.map_sfx[7]
						soundstream.play()	
												
						await get_tree().create_timer(0.1).timeout
						right_clicked_unit.get_child(0).play("default")							
						
						var tile_position = map_to_local(Vector2i(tile_pos)) + Vector2(0,0) / 2
						await SetLinePoints(line_2d, Vector2(tile_position.x,tile_position.y-200), Vector2(tile_position.x,tile_position.y-16))
						for i in cpu_units.size():
							if cpu_units[i].tile_pos == clicked_pos:
								cpu_units[i].get_child(0).play("death")
								await get_tree().create_timer(0.5).timeout	
								cpu_units[i].position.y -= 500		
								cpu_units[i].add_to_group("dead") 
								cpu_units[i].remove_from_group("zombies") 
								moving = false

								soundstream.stream = soundstream.map_sfx[5]
								soundstream.play()										
								
						get_node("../Arrow").hide()
						get_node("../Arrow2").hide()		
						await get_tree().create_timer(1).timeout
						_on_zombie()
											
					#Landmine run
					if get_cell_source_id(1, tile_pos) == 48 and right_clicked_unit.unit_type == "Dog" and right_clicked_unit.unit_name == "Robodog" and user_units[selected_unit_num].unit_name != "Snake" and dogmine_range == true:
						dogmine_range = false
						#Move unit
						if astar_grid.is_point_solid(tile_pos) == false and clicked_zombie == false:
							if dead_humans.size() == 2:					
								return
									
							check_zombies_dead()
							
							if map_cleared == true:
								return
							
							moving = true
							#Remove hover tiles										
							for j in grid_height:
								for k in grid_width:
									set_cell(1, Vector2i(j,k), -1, Vector2i(0, 0), 0)
													
							target_pos = tile_pos 
							var patharray = astar_grid.get_point_path(selected_pos, target_pos)
							
							if patharray.size() <= 0:
								moving = false
								return
													
							# Move unit		
							for k in patharray.size():	
								set_cell(1, patharray[k], 48, Vector2i(0, 0), 0)		
								user_units[selected_unit_num].get_child(0).play("move")						
								var tile_center_position = map_to_local(patharray[k]) + Vector2(0,0) / 2
								var unit_pos = local_to_map(user_units[selected_unit_num].position)
								user_units[selected_unit_num].z_index = unit_pos.x + unit_pos.y
													
								var tween = create_tween()
								tween.tween_property(user_units[selected_unit_num], "position", tile_center_position, 0.25)
								
								var landmine = preload("res://scenes/mines/landmine.scn")
								var landmine_instance = landmine.instantiate()
								var landmine_position = get_node("../TileMap").map_to_local(patharray[k]) + Vector2(0,0) / 2
								landmine_instance.set_name("landmine")
								get_parent().add_child(landmine_instance)
								landmine_instance.position = landmine_position	
								landmine_instance.z_index = (unit_pos.x + unit_pos.y) - 1
								landmine_instance.add_to_group("mines")
								landmines = get_tree().get_nodes_in_group("mines")
								all_landmines.append_array(landmines)			
								
								landmine_temp = landmine_instance		
								
								soundstream.stream = soundstream.map_sfx[0]
								soundstream.play()			
											
								await get_tree().create_timer(0.25).timeout	
								
							if landmine_temp:
								landmine_temp.position.y -= 500
								
							user_units[selected_unit_num].kill_count = 2
							user_units[selected_unit_num].get_child(0).play("default")
								
							_on_zombie()				
							
					#Place landmine
					if right_clicked_unit.position == all_units[h].position and get_cell_source_id(1, tile_pos) == 48 and right_clicked_unit.attacked == false and attack_range == false and right_clicked_unit.unit_type == "Human" and landmines_range == true:
						var attack_center_position = map_to_local(clicked_pos) + Vector2(0,0) / 2	
						
						if right_clicked_unit.scale.x == 1 and right_clicked_unit.position.x > attack_center_position.x:
							right_clicked_unit.scale.x = 1
						
						elif right_clicked_unit.scale.x == -1 and right_clicked_unit.position.x < attack_center_position.x:
							right_clicked_unit.scale.x = -1	
						
						if right_clicked_unit.scale.x == -1 and right_clicked_unit.position.x > attack_center_position.x:
							right_clicked_unit.scale.x = 1
						
						elif right_clicked_unit.scale.x == 1 and right_clicked_unit.position.x < attack_center_position.x:
							right_clicked_unit.scale.x = -1																																					
												
						right_clicked_unit.get_child(0).play("attack")	
						
						soundstream.stream = soundstream.map_sfx[3]
						soundstream.play()	
												
						await get_tree().create_timer(0.1).timeout
						right_clicked_unit.get_child(0).play("default")	
												
						await get_tree().create_timer(0.1).timeout
						right_clicked_unit.get_child(0).play("default")		
						
						var right_clicked_pos = local_to_map(right_clicked_unit.position)
						
						#get_node("../Camera2D").shake(0.5, 30, 3)
													
						if right_clicked_pos.y < clicked_pos.y and right_clicked_unit.position.x > attack_center_position.x:	
							var tile_center_pos = map_to_local(clicked_pos) + Vector2(0,0) / 2
							var landmine = preload("res://scenes/mines/landmine.scn")
							var landmine_instance = landmine.instantiate()
							var landmine_position = get_node("../TileMap").map_to_local(clicked_pos) + Vector2(0,0) / 2
							landmine_instance.set_name("landmine")
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
							landmine_instance.set_name("landmine")
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
							landmine_instance.set_name("landmine")
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
							landmine_instance.set_name("landmine")
							get_parent().add_child(landmine_instance)
							landmine_instance.position = landmine_position	
							landmine_instance.z_index = clicked_pos.x + clicked_pos.y
							landmine_instance.add_to_group("mines")
							landmines = get_tree().get_nodes_in_group("mines")
							all_landmines.append_array(landmines)
							left_clicked_unit.get_child(0).play("default")	
						
						_on_zombie()
						landmines_total += 1								
							
					
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
					if dead_humans.size() == 2:					
						return
							
					check_zombies_dead()
					
					if map_cleared == true:
						return
					
					moving = true
					#Remove hover tiles										
					for j in grid_height:
						for k in grid_width:
							set_cell(1, Vector2i(j,k), -1, Vector2i(0, 0), 0)
											
					target_pos = tile_pos 
					var patharray = astar_grid.get_point_path(selected_pos, target_pos)
					
					if patharray.size() <= 0:
						moving = false
						return
					
					# Find path and set hover cells
					for h in patharray.size():
						set_cell(1, patharray[h], 10, Vector2i(0, 0), 0)	
											
					# Move unit		
					for h in patharray.size():		
						user_units[selected_unit_num].get_child(0).play("move")						
						var tile_center_position = map_to_local(patharray[h]) + Vector2(0,0) / 2
						var unit_pos = local_to_map(user_units[selected_unit_num].position)
						user_units[selected_unit_num].z_index = unit_pos.x + unit_pos.y														
						for i in all_landmines.size():
							var mine_pos = local_to_map(all_landmines[i].position)	
							var path_pos = local_to_map(tile_center_position)
							if path_pos	== mine_pos and path_interupted == false:
								var patharray_new = astar_grid.get_point_path(mine_pos, mine_pos)
								for j in patharray_new.size():
									var tile_center_position_new = map_to_local(patharray_new[j]) + Vector2(0,0) / 2
									var unit_pos_new = local_to_map(user_units[selected_unit_num].position)
									user_units[selected_unit_num].z_index = unit_pos_new.x + unit_pos_new.y								
									path_interupted = true
									#var explosion = preload("res://scenes/vfx/explosion.scn")
									#var explosion_instance = explosion.instantiate()
									#var explosion_position = get_node("../TileMap").map_to_local(mine_pos) + Vector2(0,0) / 2
									#explosion_instance.set_name("explosion")
									#get_parent().add_child(explosion_instance)
									#explosion_instance.position = explosion_position	
									#explosion_instance.position.y -= 16
									#explosion_instance.z_index = (mine_pos.x + mine_pos.y) + 1
									var tween = create_tween()
									tween.tween_property(user_units[selected_unit_num], "position", tile_center_position_new, 0.25)									
									tween.connect("finished", on_tween_finished)
									get_node("../TileMap").all_landmines[i].position.y -= 500
									user_units[selected_unit_num].get_child(0).play("default")		
									landmines_total -= 1									
								
						if path_interupted == true:
							moving = false
							path_interupted = false
							return
							
						if path_interupted == false:		
							user_units[selected_unit_num].get_child(0).play("move")						
							var tile_center_position_2 = map_to_local(patharray[h]) + Vector2(0,0) / 2
							var tween = create_tween()
							tween.tween_property(user_units[selected_unit_num], "position", tile_center_position_2, 0.25)
							var unit_pos_2 = local_to_map(user_units[selected_unit_num].position)
							user_units[selected_unit_num].z_index = unit_pos_2.x + unit_pos_2.y			
							await get_tree().create_timer(0.25).timeout	
						
						soundstream.stream = soundstream.map_sfx[0]
						soundstream.play()		
								
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
									soundstream.stream = soundstream.map_sfx[6]
									soundstream.play()		
																		
									var tween: Tween = create_tween()
									tween.tween_property(cpu_units[j], "modulate:v", 1, 0.50).from(5)												
									await get_tree().create_timer(1).timeout
									cpu_units[j].get_child(0).play("death")
									
									soundstream.stream = soundstream.map_sfx[5]
									soundstream.play()										
									
									await get_tree().create_timer(1).timeout
									user_units[selected_unit_num].get_child(0).play("default")	
									cpu_units[j].position.y -= 500
									cpu_units[j].add_to_group("dead")
									cpu_units[j].remove_from_group("zombies")
						
									if cpu_units[j].unit_status == "Radioactive" and user_units[selected_unit_num].unit_type != "Dog":
										var tween2: Tween = create_tween()
										tween2.tween_property(user_units[selected_unit_num], "modulate:v", 1, 0.50).from(5)												
										soundstream.stream = soundstream.map_sfx[6]
										soundstream.play()												
										await get_tree().create_timer(1).timeout										
										user_units[selected_unit_num].get_child(0).play("death_radioactive")	
										user_units[selected_unit_num].add_to_group("humans dead")
										soundstream.stream = soundstream.map_sfx[8]
										soundstream.play()											
										await get_tree().create_timer(1).timeout
										user_units[selected_unit_num].position.y -= 500
																
									user_units[selected_unit_num].moved = true
									user_units[selected_unit_num].kill_count += 1									
									_on_zombie()
									return
									
					_on_zombie()						
						
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
							elif landmines_range == true:
								pass
							elif landmines_range == false:
								all_units[i].selected = false
								#Remove hover tiles										
								for m in grid_height:
									for n in grid_width:
										set_cell(1, Vector2i(m,n), -1, Vector2i(0, 0), 0)
																								
				for i in all_units.size():					
					if all_units[i].unit_type == "Dog" and all_units[i].moved == false and all_units[i].kill_count < 2:		
						#Place hover tiles		
						for j in dogs.size():
							var unit_pos = local_to_map(dogs[j].position)
							if unit_pos == tile_pos:					
								show_dog_movement_range()	
								all_units[i].selected = true
								clicked_zombie = false
								attack_range = false
								return
							elif landmines_range == true:
								pass
							elif landmines_range == false:
								all_units[i].selected = false
								#Remove hover tiles										
								for m in grid_height:
									for n in grid_width:
										set_cell(1, Vector2i(m,n), -1, Vector2i(0, 0), 0)
					elif all_units[i].unit_type == "Dog" and all_units[i].kill_count >= 2:
						all_units[i].fuel_dog()
																			
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
							elif landmines_range == true:
								pass
							elif landmines_range == false:
								user_units[selected_unit_num].selected = false
								#Remove hover tiles										
								for m in grid_height:
									for n in grid_width:
										set_cell(1, Vector2i(m,n), -1, Vector2i(0, 0), 0)	
				
		if event.button_index == MOUSE_BUTTON_RIGHT and get_node("../SpawnManager").spawn_complete == true and moving == false and swarming == false:	
			if event.pressed:			
				hovertile.show()			
				#Remove hover tiles										
				for j in grid_height:
					for k in grid_width:
						set_cell(1, Vector2i(j,k), -1, Vector2i(0, 0), 0)
																				
				var mouse_pos = get_global_mouse_position()
				mouse_pos.y += 8
				var tile_pos = local_to_map(mouse_pos)		
				var tile_data = get_cell_tile_data(0, tile_pos)

				for i in user_units.size():
					if user_units[i].tile_pos == tile_pos:
						selected_unit_num = user_units[i].unit_num
						selected_pos = user_units[i].tile_pos								
						break

				if tile_data is TileData:				
					for i in user_units.size():
						var unit_pos = local_to_map(user_units[i].position)

						if unit_pos == tile_pos and user_units[i].unit_name != "Snake":							
							attack_range = true
							landmines_range = false
							right_clicked_unit = user_units[i]

							if user_units[i].unit_type == "Dog":
								dog_range = true

							if user_units[i].kill_count >= 2 and user_units[i].unit_type == "Dog":
								return
														
							var hoverflag_1 = true															
							for j in 16:	
								set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
								if hoverflag_1 == true:
									for k in node2D.structures.size():
										if tile_pos.x-j >= 0:	
											set_cell(1, Vector2i(tile_pos.x-j, tile_pos.y), 48, Vector2i(0, 0), 0)
											if astar_grid.is_point_solid(Vector2i(tile_pos.x-j, tile_pos.y)) == true and user_units[i].tile_pos != Vector2i(tile_pos.x-j, tile_pos.y):
												hoverflag_1 = false
												break	
									
							var hoverflag_2 = true										
							for j in 16:	
								set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
								if hoverflag_2 == true:											
									for k in node2D.structures.size():																						
										if tile_pos.y+j <= 16:
											set_cell(1, Vector2i(tile_pos.x, tile_pos.y+j), 48, Vector2i(0, 0), 0)
											if astar_grid.is_point_solid(Vector2i(tile_pos.x, tile_pos.y+j)) == true and user_units[i].tile_pos != Vector2i(tile_pos.x, tile_pos.y+j):
												hoverflag_2 = false
												break

							var hoverflag_3 = true	
							for j in 16:	
								set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
								if hoverflag_3 == true:											
									for k in node2D.structures.size():																													
										if tile_pos.x+j <= 16:
											set_cell(1, Vector2i(tile_pos.x+j, tile_pos.y), 48, Vector2i(0, 0), 0)
											if astar_grid.is_point_solid(Vector2i(tile_pos.x+j, tile_pos.y)) == true and user_units[i].tile_pos != Vector2i(tile_pos.x+j, tile_pos.y):
												hoverflag_3 = false
												break

							var hoverflag_4 = true	
							for j in 16:	
								set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
								if hoverflag_4 == true:											
									for k in node2D.structures.size():																											
										if tile_pos.y-j >= 0:									
											set_cell(1, Vector2i(tile_pos.x, tile_pos.y-j), 48, Vector2i(0, 0), 0)
											if astar_grid.is_point_solid(Vector2i(tile_pos.x, tile_pos.y-j)) == true and user_units[i].tile_pos != Vector2i(tile_pos.x, tile_pos.y-j):
												hoverflag_4 = false
												break
						
						if unit_pos == tile_pos and user_units[i].unit_name == "Snake":
							right_clicked_unit = user_units[i]						
							show_rambo_attack_range()
						
				if tile_pos.x == 0:
					set_cell(1, Vector2i(tile_pos.x-1, tile_pos.y), -1, Vector2i(0, 0), 0)
				if tile_pos.y == 0:
					set_cell(1, Vector2i(tile_pos.x, tile_pos.y-1), -1, Vector2i(0, 0), 0)							
				if tile_pos.x == 15:
					set_cell(1, Vector2i(tile_pos.x+1, tile_pos.y), -1, Vector2i(0, 0), 0)
				if tile_pos.y == 15:
					set_cell(1, Vector2i(tile_pos.x, tile_pos.y+1), -1, Vector2i(0, 0), 0)	

				soundstream.stream = soundstream.map_sfx[2]
				soundstream.play()				

func _on_zombie():	
	zombie_button.hide()
	landmine_once = true
	
	for i in user_units.size():
		modulate = Color8(255, 255, 255)
		user_units[i].moved = false
		user_units[i].attacked = false

	#Remove hover tiles										
	for j in grid_height:
		for k in grid_width:
			set_cell(1, Vector2i(j,k), -1, Vector2i(0, 0), 0)
	
	moving = false		
	
	humans = get_tree().get_nodes_in_group("humans")
	if humans.size() == 0:
		return
	var target_human = rng.randi_range(0,humans.size()-1)
	var human_position = get_node("../TileMap").map_to_local(humans[target_human].tile_pos) + Vector2(0,0) / 2 
	var closest_zombie_to_human = humans[target_human].get_closest_attack_zombies()
	
	var dead_humans = get_tree().get_nodes_in_group("humans dead")
	if dead_humans.size() == 2:
		moving = false
		swarming = false	
		check_humans_dead()
		return	
			
	if closest_zombie_to_human == null:
		return
	if !humans[target_human].is_in_group("humans dead") and !closest_zombie_to_human.is_in_group("dead"):
		get_node("../Arrow2").show()
		get_node("../Arrow2").position = humans[target_human].position
		var arrow_pos2 = local_to_map(get_node("../Arrow2").position)
		get_node("../Arrow2").z_index = (arrow_pos2.x + arrow_pos2.y) + 3	

		get_node("../Arrow").show()
		get_node("../Arrow").position = closest_zombie_to_human.position
		var arrow_pos = local_to_map(get_node("../Arrow").position)
		get_node("../Arrow").z_index = (arrow_pos.x + arrow_pos.y) + 3	
	else:		
		_on_zombie()
		return		
	
	moving = true
	
	swarm_turns += 1
	
	zombies = get_tree().get_nodes_in_group("zombies")
	
	if swarm_turns == 3:
		swarming = true
		for i in zombies.size():
			if zombies.size() == 0:
				moving = false
				swarming = false
				return			
			soundstream.stream = soundstream.map_sfx[4] 
			soundstream.play()		
			await zombie_attack_swarm()
		index = 0	
		swarm_turns = 0	
		swarming = false
		random_once = false
	else:
		await zombie_attack_ai(target_human, closest_zombie_to_human)
							
func zombie_attack_ai(target_human: int, closest_zombie_to_human: Area2D):
	zombies = get_tree().get_nodes_in_group("zombies")
	
	if !closest_zombie_to_human:		
		return
	
	if closest_zombie_to_human.is_in_group("dead") or humans[target_human].is_in_group("humans dead"):
		_on_zombie()
				
	if !closest_zombie_to_human.is_in_group("dead") and !humans[target_human].is_in_group("humans dead"):
		var closest_atack = humans[target_human]									
		var zombie_target_pos = local_to_map(closest_atack.position)
		var zombie_surrounding_cells = get_surrounding_cells(zombie_target_pos)
		
		closest_zombie_to_human.get_child(0).play("move")
		var open_tile = rng.randi_range(0,3)
		if astar_grid.is_point_solid(zombie_surrounding_cells[open_tile]) == false and get_cell_source_id(0, zombie_surrounding_cells[open_tile]) != -1 and structure_interupterd == false: 
			get_node("../Arrow").hide()
			
			var patharray = astar_grid.get_point_path(closest_zombie_to_human.tile_pos, zombie_surrounding_cells[open_tile])
			# Find path and set hover cells
			for h in patharray.size():
				await get_tree().create_timer(0.01).timeout
				set_cell(1, patharray[h], 10, Vector2i(0, 0), 0)
				if h == closest_zombie_to_human.unit_movement:
					get_node("../TileMap").set_cell(1, patharray[h], 18, Vector2i(0, 0), 0)			
				
			# Move unit		
			for h in patharray.size():
				var tile_center_position = map_to_local(patharray[h]) + Vector2(0,0) / 2
				var tween = create_tween()
				tween.tween_property(closest_zombie_to_human, "position", tile_center_position, 0.25)
				var unit_pos = local_to_map(closest_zombie_to_human.position)
				closest_zombie_to_human.z_index = unit_pos.x + unit_pos.y			
				await get_tree().create_timer(0.25).timeout
				for i in all_landmines.size():
					var mine_pos = local_to_map(all_landmines[i].position)	
					var path_pos = local_to_map(tile_center_position)
					if path_pos	== mine_pos:
						closest_zombie_to_human.landmine_collisions()	
						# Remove hover cells
						for j in patharray.size():
							set_cell(1, patharray[j], -1, Vector2i(0, 0), 0)							
						return		
						
				for i in node2D.structures.size():
					var structure_pos = local_to_map(node2D.structures[i].position)	
					var path_pos = local_to_map(tile_center_position)
					if path_pos	== structure_pos:
						structure_interupterd = true
						closest_zombie_to_human.structure_collisions()	
						# Remove hover cells
						for j in patharray.size():
							set_cell(1, patharray[j], -1, Vector2i(0, 0), 0)							
						return		
							
							
				if h == closest_zombie_to_human.unit_movement:
					break
				
				soundstream.stream = soundstream.map_sfx[0]
				soundstream.play()						
					
			moving = false
							
			# Remove hover cells
			for h in patharray.size():
				set_cell(1, patharray[h], -1, Vector2i(0, 0), 0)
			
			closest_zombie_to_human.get_child(0).play("default")	
			
			for i in 4:
				var zombies_pos = local_to_map(closest_zombie_to_human.position)
				if zombies_pos == zombie_surrounding_cells[i]:
					var attack_center_position = map_to_local(zombie_target_pos) + Vector2(0,0) / 2	
								
					if closest_zombie_to_human.scale.x == 1 and closest_zombie_to_human.position.x > attack_center_position.x:
						closest_zombie_to_human.scale.x = 1
					elif closest_zombie_to_human.scale.x == -1 and closest_zombie_to_human.position.x < attack_center_position.x:
						closest_zombie_to_human.scale.x = -1	
					if closest_zombie_to_human.scale.x == -1 and closest_zombie_to_human.position.x > attack_center_position.x:
						closest_zombie_to_human.scale.x = 1
					elif closest_zombie_to_human.scale.x == 1 and closest_zombie_to_human.position.x < attack_center_position.x:
						closest_zombie_to_human.scale.x = -1						
		

					closest_zombie_to_human.get_child(0).play("attack")
					var tween: Tween = create_tween()
					tween.tween_property(closest_atack, "modulate:v", 1, 0.50).from(5)		
					
					soundstream.stream = soundstream.map_sfx[4]
					soundstream.play()							
						
					await get_tree().create_timer(1).timeout
					closest_atack.get_child(0).play("death")	
					
					soundstream.stream = soundstream.map_sfx[8]
					soundstream.play()		
									
					await get_tree().create_timer(1).timeout
					closest_atack.add_to_group("humans dead")
					closest_atack.position.y -= 500
					closest_zombie_to_human.get_child(0).play("default")	
					break
					
			moving = false
		else:
			zombie_attack_ai(target_human, closest_zombie_to_human)

	get_node("../Arrow").show()
	get_node("../Arrow").position = closest_zombie_to_human.position
	var arrow_pos = local_to_map(get_node("../Arrow").position)
	get_node("../Arrow").z_index = (arrow_pos.x + arrow_pos.y) + 3		

	get_node("../Arrow2").show()
	get_node("../Arrow2").position = humans[target_human].position
	var arrow_pos2 = local_to_map(get_node("../Arrow2").position)
	get_node("../Arrow2").z_index = (arrow_pos2.x + arrow_pos2.y) + 3	
	
	check_humans_dead()	

func zombie_attack_swarm():
	var dead_humans = get_tree().get_nodes_in_group("humans dead")
	if dead_humans.size() == 2:
		moving = false
		swarming = false	
		check_humans_dead()
		return		
			
	zombies = get_tree().get_nodes_in_group("zombies")
	if zombies.size() == 0:
		moving = false
		swarming = false		
		return	
					
	var target_human = rng.randi_range(0,humans.size()-1)
	var closest_zombie_to_human = zombies[index]
	index += 1
	
	if index == zombies.size():
		index = 0
	
	if !closest_zombie_to_human:		
		return
	
	if closest_zombie_to_human.is_in_group("dead") or humans[target_human].is_in_group("humans dead"):
		await zombie_attack_swarm()
		return
				
	if !closest_zombie_to_human.is_in_group("dead") and !humans[target_human].is_in_group("humans dead"):
		var closest_atack = humans[target_human]									
		var zombie_target_pos = local_to_map(closest_atack.position)
		var zombie_surrounding_cells = get_surrounding_cells(zombie_target_pos)
		
		closest_zombie_to_human.get_child(0).play("move")
		var open_tile = rng.randi_range(0,3)
		if astar_grid.is_point_solid(zombie_surrounding_cells[open_tile]) == false and get_cell_source_id(0, zombie_surrounding_cells[open_tile]) != -1 and structure_interupterd == false: 
			get_node("../Arrow").hide()
			
			var patharray = astar_grid.get_point_path(closest_zombie_to_human.tile_pos, zombie_surrounding_cells[open_tile])
			# Find path and set hover cells
			for h in patharray.size():
				await get_tree().create_timer(0.01).timeout
				set_cell(1, patharray[h], 10, Vector2i(0, 0), 0)
				if h == closest_zombie_to_human.unit_movement:
					get_node("../TileMap").set_cell(1, patharray[h], 18, Vector2i(0, 0), 0)			
				
			# Move unit		
			for h in patharray.size():
				var tile_center_position = map_to_local(patharray[h]) + Vector2(0,0) / 2
				var tween = create_tween()
				tween.tween_property(closest_zombie_to_human, "position", tile_center_position, 0.25)
				var unit_pos = local_to_map(closest_zombie_to_human.position)
				closest_zombie_to_human.z_index = unit_pos.x + unit_pos.y			
				await get_tree().create_timer(0.25).timeout
				for i in all_landmines.size():
					var mine_pos = local_to_map(all_landmines[i].position)	
					var path_pos = local_to_map(tile_center_position)
					if path_pos	== mine_pos:
						closest_zombie_to_human.landmine_collisions()	
						# Remove hover cells
						for j in patharray.size():
							set_cell(1, patharray[j], -1, Vector2i(0, 0), 0)							
						return		
						
				for i in node2D.structures.size():
					var structure_pos = local_to_map(node2D.structures[i].position)	
					var path_pos = local_to_map(tile_center_position)
					if path_pos	== structure_pos:
						structure_interupterd = true
						closest_zombie_to_human.structure_collisions()	
						# Remove hover cells
						for j in patharray.size():
							set_cell(1, patharray[j], -1, Vector2i(0, 0), 0)							
						return		
							
							
				if h == closest_zombie_to_human.unit_movement:
					break
				
				soundstream.stream = soundstream.map_sfx[0]
				soundstream.play()						
					
			moving = false
							
			# Remove hover cells
			for h in patharray.size():
				set_cell(1, patharray[h], -1, Vector2i(0, 0), 0)
			
			closest_zombie_to_human.get_child(0).play("default")	
			
			for i in 4:
				var zombies_pos = local_to_map(closest_zombie_to_human.position)
				if zombies_pos == zombie_surrounding_cells[i]:
					var attack_center_position = map_to_local(zombie_target_pos) + Vector2(0,0) / 2	
								
					if closest_zombie_to_human.scale.x == 1 and closest_zombie_to_human.position.x > attack_center_position.x:
						closest_zombie_to_human.scale.x = 1
					elif closest_zombie_to_human.scale.x == -1 and closest_zombie_to_human.position.x < attack_center_position.x:
						closest_zombie_to_human.scale.x = -1	
					if closest_zombie_to_human.scale.x == -1 and closest_zombie_to_human.position.x > attack_center_position.x:
						closest_zombie_to_human.scale.x = 1
					elif closest_zombie_to_human.scale.x == 1 and closest_zombie_to_human.position.x < attack_center_position.x:
						closest_zombie_to_human.scale.x = -1						
		

					closest_zombie_to_human.get_child(0).play("attack")
					var tween: Tween = create_tween()
					tween.tween_property(closest_atack, "modulate:v", 1, 0.50).from(5)		
					
					soundstream.stream = soundstream.map_sfx[4]
					soundstream.play()							
						
					await get_tree().create_timer(1).timeout
					closest_atack.get_child(0).play("death")	
					
					soundstream.stream = soundstream.map_sfx[8]
					soundstream.play()		
									
					await get_tree().create_timer(1).timeout
					closest_atack.add_to_group("humans dead")
					closest_atack.position.y -= 500
					closest_zombie_to_human.get_child(0).play("default")	
					break
					
			moving = false
			
			dead_humans = get_tree().get_nodes_in_group("humans dead")
			if dead_humans.size() == 2:
				moving = false
				swarming = false	
				return			
		else:
			await zombie_attack_swarm()
			closest_zombie_to_human.get_child(0).play("default")	
			

	get_node("../Arrow").show()
	get_node("../Arrow").position = closest_zombie_to_human.position
	var arrow_pos = local_to_map(get_node("../Arrow").position)
	get_node("../Arrow").z_index = (arrow_pos.x + arrow_pos.y) + 3		

	get_node("../Arrow2").show()
	get_node("../Arrow2").position = humans[target_human].position
	var arrow_pos2 = local_to_map(get_node("../Arrow2").position)
	get_node("../Arrow2").z_index = (arrow_pos2.x + arrow_pos2.y) + 3	
	
	check_humans_dead()	
			
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
	
	soundstream.stream = soundstream.map_sfx[1]
	soundstream.play()		
	
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
	
	#attacks_container.show()
	mines_button.show()
	dog_mines_button.hide()	

	soundstream.stream = soundstream.map_sfx[1]
	soundstream.play()		
	
func show_rambo_attack_range():
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
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y), 48, Vector2i(0, 0), 0)
						if surrounding_cells[k].x <= -1 or surrounding_cells[k].y >= 16 or surrounding_cells[k].x >= 16 or surrounding_cells[k].y <= -1:
							set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
							set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y), -1, Vector2i(0, 0), 0)										
				
				if humans[i].unit_movement == 2:
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y), 48, Vector2i(0, 0), 0)										
						if surrounding_cells[k].x <= -1 or surrounding_cells[k].y >= 16 or surrounding_cells[k].x >= 16 or surrounding_cells[k].y <= -1:
							set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
							set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y), -1, Vector2i(0, 0), 0)								
					for k in surrounding_cells.size():
						set_cell(1, Vector2i(surrounding_cells[k].x+1, surrounding_cells[k].y), 48, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x-1, surrounding_cells[k].y), 48, Vector2i(0, 0), 0)															
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+1), 48, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-1), 48, Vector2i(0, 0), 0)									
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)	
				
				if humans[i].unit_movement == 3:
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y), 48, Vector2i(0, 0), 0)									
						if surrounding_cells[k].x <= -1 or surrounding_cells[k].y >= 16 or surrounding_cells[k].x >= 16 or surrounding_cells[k].y <= -1:
							set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
							set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y), -1, Vector2i(0, 0), 0)								
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x+1, surrounding_cells[k].y), 48, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x-1, surrounding_cells[k].y), 48, Vector2i(0, 0), 0)															
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+1), 48, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-1), 48, Vector2i(0, 0), 0)								
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x+2, surrounding_cells[k].y), 48, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x-2, surrounding_cells[k].y), 48, Vector2i(0, 0), 0)															
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+2), 48, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-2), 48, Vector2i(0, 0), 0)						

				if humans[i].unit_movement == 4:
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y), 48, Vector2i(0, 0), 0)									
						if surrounding_cells[k].x <= -1 or surrounding_cells[k].y >= 16 or surrounding_cells[k].x >= 16 or surrounding_cells[k].y <= -1:
							set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
							set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y), -1, Vector2i(0, 0), 0)								
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x+1, surrounding_cells[k].y), 48, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x-1, surrounding_cells[k].y), 48, Vector2i(0, 0), 0)															
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+1), 48, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-1), 48, Vector2i(0, 0), 0)								
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x+2, surrounding_cells[k].y), 48, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x-2, surrounding_cells[k].y), 48, Vector2i(0, 0), 0)															
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+2), 48, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-2), 48, Vector2i(0, 0), 0)															
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x+3, surrounding_cells[k].y), 48, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x-3, surrounding_cells[k].y), 48, Vector2i(0, 0), 0)															
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+3), 48, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-3), 48, Vector2i(0, 0), 0)	
						
					set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
					set_cell(1, Vector2i(unit_pos.x+2, unit_pos.y+2), 48, Vector2i(0, 0), 0)																																								
					set_cell(1, Vector2i(unit_pos.x-2, unit_pos.y-2), 48, Vector2i(0, 0), 0)															
					set_cell(1, Vector2i(unit_pos.x+2, unit_pos.y-2), 48, Vector2i(0, 0), 0)																																								
					set_cell(1, Vector2i(unit_pos.x-2, unit_pos.y+2), 48, Vector2i(0, 0), 0)			

				if humans[i].unit_movement == 5:
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y), 48, Vector2i(0, 0), 0)									
						if surrounding_cells[k].x <= -1 or surrounding_cells[k].y >= 16 or surrounding_cells[k].x >= 16 or surrounding_cells[k].y <= -1:
							set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
							set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y), -1, Vector2i(0, 0), 0)								
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x+1, surrounding_cells[k].y), 48, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x-1, surrounding_cells[k].y), 48, Vector2i(0, 0), 0)															
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+1), 48, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-1), 48, Vector2i(0, 0), 0)								
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x+2, surrounding_cells[k].y), 48, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x-2, surrounding_cells[k].y), 48, Vector2i(0, 0), 0)															
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+2), 48, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-2), 48, Vector2i(0, 0), 0)															
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x+3, surrounding_cells[k].y), 48, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x-3, surrounding_cells[k].y), 48, Vector2i(0, 0), 0)															
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+3), 48, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-3), 48, Vector2i(0, 0), 0)	
					for k in surrounding_cells.size():
						set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
						set_cell(1, Vector2i(surrounding_cells[k].x+4, surrounding_cells[k].y), 48, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x-4, surrounding_cells[k].y), 48, Vector2i(0, 0), 0)															
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y+4), 48, Vector2i(0, 0), 0)																																								
						set_cell(1, Vector2i(surrounding_cells[k].x, surrounding_cells[k].y-4), 48, Vector2i(0, 0), 0)	
															
					set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
					set_cell(1, Vector2i(unit_pos.x+2, unit_pos.y+2), 48, Vector2i(0, 0), 0)																																								
					set_cell(1, Vector2i(unit_pos.x-2, unit_pos.y-2), 48, Vector2i(0, 0), 0)															
					set_cell(1, Vector2i(unit_pos.x+2, unit_pos.y-2), 48, Vector2i(0, 0), 0)																																								
					set_cell(1, Vector2i(unit_pos.x-2, unit_pos.y+2), 48, Vector2i(0, 0), 0)	

					set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
					set_cell(1, Vector2i(unit_pos.x+2, unit_pos.y+3), 48, Vector2i(0, 0), 0)																																								
					set_cell(1, Vector2i(unit_pos.x-3, unit_pos.y-2), 48, Vector2i(0, 0), 0)															
					set_cell(1, Vector2i(unit_pos.x+2, unit_pos.y-3), 48, Vector2i(0, 0), 0)																																								
					set_cell(1, Vector2i(unit_pos.x-3, unit_pos.y+2), 48, Vector2i(0, 0), 0)	

					set_cell(1, tile_pos, -1, Vector2i(0, 0), 0)
					set_cell(1, Vector2i(unit_pos.x+3, unit_pos.y+2), 48, Vector2i(0, 0), 0)																																								
					set_cell(1, Vector2i(unit_pos.x-2, unit_pos.y-3), 48, Vector2i(0, 0), 0)															
					set_cell(1, Vector2i(unit_pos.x+3, unit_pos.y-2), 48, Vector2i(0, 0), 0)																																								
					set_cell(1, Vector2i(unit_pos.x-2, unit_pos.y+3), 48, Vector2i(0, 0), 0)				
	
	attacks_container.show()
	
	soundstream.stream = soundstream.map_sfx[1]
	soundstream.play()		
	
func show_laser_range():
	hovertile.show()			
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
				dogmine_range = true
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

	soundstream.stream = soundstream.map_sfx[2]
	soundstream.play()			

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
	
	soundstream.stream = soundstream.map_sfx[2]
	soundstream.play()		
			
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
		left_clicked_unit_position = dogs[i].position		
		if unit_pos == tile_pos:
			#Place hover tiles on all tiles										
			for j in grid_height:
				for k in grid_width:
					set_cell(1, Vector2i(j,k), 10, Vector2i(0, 0), 0)
					set_cell(1, unit_pos, -1, Vector2i(0, 0), 0)
					
	attacks_container.show()	
	mines_button.hide()
	dog_mines_button.show()			

	soundstream.stream = soundstream.map_sfx[1]
	soundstream.play()		
		
func on_tween_finished():			
	_on_zombie()

func check_zombies_dead():
	dead_zombies = get_tree().get_nodes_in_group("dead")
			
	if dead_zombies.size() == cpu_units.size():
		print("Map Cleared!")
		map_cleared = true	
		next_button.show()
		reset_button.hide()
		await get_tree().create_timer(0).timeout
		get_node("../Arrow").modulate.a = 0
		get_node("../Arrow2").modulate.a = 0			

func check_humans_dead():
	dead_humans = get_tree().get_nodes_in_group("humans dead")
			
	if dead_humans.size() == 2:
		get_node("../Arrow").modulate.a = 0
		get_node("../Arrow2").modulate.a = 0
		print("Zombies Win!")	

		soundstream.stream = soundstream.map_sfx[9]
		soundstream.play()		
		musicstream.stop()	
		await get_tree().create_timer(1).timeout
		get_tree().reload_current_scene()
		
func SetLinePoints(line: Line2D, a: Vector2, b: Vector2):
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

func _on_landmine_button_pressed():
	show_humans_landmine_range()
	
func _on_next_button_pressed():
	get_tree().reload_current_scene()

func _on_laser_button_pressed():
	show_laser_range()	

func get_random_numbers(from, to):
	var arr = []
	for i in range(from,to):
		arr.append(i)
	arr.shuffle()
	return arr	
