extends TileMap

var grid = []
var grid_width = 16
var grid_height = 16

var rng = RandomNumberGenerator.new()

@export var hovertile: Sprite2D
@export var zombie: Area2D

var astar_grid = AStarGrid2D.new()

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

func zombie_attack_ai():
	var zombies = get_tree().get_nodes_in_group("zombies")
	var active_zombie = rng.randi_range(0,15)
	var target_zombie = rng.randi_range(0,15)			
	if !zombies[active_zombie].is_in_group("dead") and !zombies[target_zombie].is_in_group("dead"):										
		var zombie_target_pos = local_to_map(zombies[target_zombie].position)
		var zombie_surrounding_cells = get_surrounding_cells(zombie_target_pos)
		
		zombies[active_zombie].get_child(0).play("move")
		var open_tile = rng.randi_range(0,3)
		if astar_grid.is_point_solid(zombie_surrounding_cells[open_tile]) == false: 
			var patharray = astar_grid.get_point_path(zombies[active_zombie].tile_pos, zombie_surrounding_cells[open_tile])
			# Find path and set hover cells
			for h in patharray.size():
				await get_tree().create_timer(0.01).timeout
				set_cell(1, patharray[h], 10, Vector2i(0, 0), 0)
			# Move unit		
			for h in patharray.size():
				var tile_center_position = map_to_local(patharray[h]) + Vector2(0,0) / 2
				var tween = create_tween()
				tween.tween_property(zombies[active_zombie], "position", tile_center_position, 0.25)
				var unit_pos = local_to_map(zombies[active_zombie].position)
				zombies[active_zombie].z_index = unit_pos.x + unit_pos.y			
				await get_tree().create_timer(0.25).timeout
			
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
			tween.tween_property(zombies[target_zombie], "modulate:v", 1, 0.50).from(5)			
			await get_tree().create_timer(1).timeout
			zombies[active_zombie].get_child(0).play("default")
			zombies[target_zombie].get_closest_attack().get_child(0).play("death")	
			zombies[target_zombie].add_to_group("dead")
			
			zombie_attack_ai()
			
		else:
			zombie_attack_ai()		
	else:
		var dead_zombies = get_tree().get_nodes_in_group("dead")
		if dead_zombies.size() >= 15:
			return
		else:
			zombie_attack_ai()
		
		
			
			
			
			
			
			
			
			
			
			
			
			
			
