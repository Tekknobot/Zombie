extends Control

var rng = RandomNumberGenerator.new()

@onready var Portrait : = $Portrait
@onready var Dialogue : = $Dialogue
@onready var Map : = $"../../TileMap"
@onready var Hovertile : = $"../../Hovertile"

var soldier = preload("res://assets/portraits/soldier_port.png")
var zombie = preload("res://assets/portraits/zombie_port.png")
var dog = preload("res://assets/portraits/dog_port.png")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _input(event):
	if event is InputEventKey:	
		if event.pressed and event.keycode == KEY_ESCAPE:
			get_tree().quit()
				
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:	
			if event.pressed:
				# Tile hover
				var mouse_position = get_global_mouse_position()
				mouse_position.y += 8
				var tile_pos = Map.local_to_map(mouse_position)
				var tile_center_pos = Map.map_to_local(tile_pos) + Vector2(0,0) / 2
				
				for i in Map.all_units.size():				
					if Map.all_units[i].unit_type == "Zombie" and Map.all_units[i].tile_pos == tile_pos:	
						Portrait.texture = zombie
					if Map.all_units[i].unit_name == "Butch" and Map.all_units[i].tile_pos == tile_pos:	
						Portrait.texture = soldier
					if Map.all_units[i].unit_type == "Dog" and Map.all_units[i].tile_pos == tile_pos:	
						Portrait.texture = dog		
