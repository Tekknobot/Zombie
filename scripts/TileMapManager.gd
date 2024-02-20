extends TileMap

var grid = []
var grid_width = 16
var grid_height = 16

var rng = RandomNumberGenerator.new()

@export var hovertile: Sprite2D
@export var zombie: Area2D

var astar_grid = AStarGrid2D.new()
var zombies = []
var dogs = []

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
		if astar_grid.is_point_solid(zombie_surrounding_cells[open_tile]) == false: 
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
			await get_tree().create_timer(1).timeout
			closest_atack.add_to_group("dead")
			closest_atack.remove_from_group("zombies")
			
			if zombies.size() <= 2:
				return
			else:
				dog_attack_ai()
		else:
			dog_attack_ai()
	else:
		dog_attack_ai()		
			
			
			
			
			
			
