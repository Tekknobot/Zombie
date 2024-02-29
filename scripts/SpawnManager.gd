extends Node2D

@export var node2D: Node2D
@export var spawn_button: Button
@export var zombie_button: Button

var rng = RandomNumberGenerator.new()

var open_tiles = []
var random = []

var zombie = preload("res://scenes/sprites/Zombie.scn")
var dog = preload("res://scenes/sprites/Dog.scn")
var soldier = preload("res://scenes/sprites/Soldier.scn")
var rambo = preload("res://scenes/sprites/Rambo.scn")

var spawn_complete = false
var zombie_init_count = 16

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func spawn():
	spawn_button.hide()
	#zombie_button.show()
	
	await get_tree().create_timer(1).timeout
	
	# Find open tiles
	open_tiles.clear()	
	for i in 16:
		for j in 16:
			if get_node("../TileMap").astar_grid.is_point_solid(Vector2i(i,j)) == false:			
				open_tiles.append(Vector2i(i,j))
	
	random.clear()
	random = get_random_numbers(128, open_tiles.size())

	# Drop dogs at start	
	for i in 1:	
		var dog_inst = dog.instantiate()
		node2D.add_child(dog_inst)
		dog_inst.add_to_group("dogs")			
		var new_position = get_node("../TileMap").map_to_local(open_tiles[random[i]]) + Vector2(0,0) / 2
		dog_inst.position = Vector2(new_position.x, new_position.y-500)
		var tween: Tween = create_tween()
		tween.tween_property(dog_inst, "position", new_position, 1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)	
		get_node("../TileMap").astar_grid.set_point_solid(new_position, true)
		get_node("../TileMap").right_clicked_unit = dog_inst
		await get_tree().create_timer(0).timeout

	await get_tree().create_timer(1).timeout
	
	# Find open tiles again
	open_tiles.clear()	
	for i in 16:
		for j in 16:
			if get_node("../TileMap").astar_grid.is_point_solid(Vector2i(i,j)) == false:			
				open_tiles.append(Vector2i(i,j))
	
	random.clear()
	random = get_random_numbers(128, open_tiles.size())

	# Drop soldier at start	
	for i in 1:	
		var soldier_inst = soldier.instantiate()
		node2D.add_child(soldier_inst)
		soldier_inst.add_to_group("humans")			
		var new_position = get_node("../TileMap").map_to_local(open_tiles[random[i]]) + Vector2(0,0) / 2
		soldier_inst.position = Vector2(new_position.x, new_position.y-500)
		var tween: Tween = create_tween()
		tween.tween_property(soldier_inst, "position", new_position, 1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)	
		get_node("../TileMap").astar_grid.set_point_solid(new_position, true)
		await get_tree().create_timer(0).timeout

	await get_tree().create_timer(1).timeout
	
	# Find open tiles again
	open_tiles.clear()	
	for i in 16:
		for j in 16:
			if get_node("../TileMap").astar_grid.is_point_solid(Vector2i(i,j)) == false:			
				open_tiles.append(Vector2i(i,j))
	
	random.clear()
	random = get_random_numbers(128, open_tiles.size())

	# Drop Rambo at start	
	for i in 1:	
		var rambo_inst = rambo.instantiate()
		node2D.add_child(rambo_inst)
		rambo_inst.add_to_group("humans")			
		var new_position = get_node("../TileMap").map_to_local(open_tiles[random[i]]) + Vector2(0,0) / 2
		rambo_inst.position = Vector2(new_position.x, new_position.y-500)
		var tween: Tween = create_tween()
		tween.tween_property(rambo_inst, "position", new_position, 1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)	
		get_node("../TileMap").astar_grid.set_point_solid(new_position, true)
		await get_tree().create_timer(0).timeout

	await get_tree().create_timer(1).timeout
	
	# Find open tiles again
	open_tiles.clear()	
	for i in 16:
		for j in 16:
			if get_node("../TileMap").astar_grid.is_point_solid(Vector2i(i,j)) == false:			
				open_tiles.append(Vector2i(i,j))
	
	random.clear()
	random = get_random_numbers(0, open_tiles.size()/2)

	# Drop zombies at start	
	for i in zombie_init_count:
		var zomb = zombie.instantiate()
		node2D.add_child(zomb)
		zomb.add_to_group("zombies")			
		var new_position = get_node("../TileMap").map_to_local(open_tiles[random[i]]) + Vector2(0,0) / 2
		zomb.position = Vector2(new_position.x, new_position.y-500)
		var tween: Tween = create_tween()
		tween.tween_property(zomb, "position", new_position, 1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)	
		get_node("../TileMap").astar_grid.set_point_solid(new_position, true)
		await get_tree().create_timer(0).timeout
									
	await get_tree().create_timer(1).timeout	
	Dialogic.start('timeline')
	spawn_complete = true
	
func get_random_numbers(from, to):
	var arr = []
	for i in range(from,to):
		arr.append(i)
	arr.shuffle()
	return arr	

func _on_spawn_button_pressed():
	await spawn()
	#get_node("../TileMap").zombie_attack_ai()
