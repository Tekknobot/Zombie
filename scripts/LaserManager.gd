extends Node2D

@export var Map: TileMap
@export var node2D: Node2D

var point1 : Vector2 = Vector2(0, 0)
var width : int = 2
var color : Color = Color.RED
@export var antialiasing : bool = true

@onready var line_2d = $"../Line2D"

var _point2 : Vector2

func _process(_delta):
	pass

func draw_laser():
	#Remove hover tiles										
	for j in node2D.grid_height:
		for k in node2D.grid_width:
			get_node("../TileMap").set_cell(1, Vector2i(j,k), -1, Vector2i(0, 0), 0)
								
	get_node("../TileMap").hovertile.hide()
	line_2d.show()		
	line_2d.set_joint_mode(2)
	var curve := Curve2D.new()
	curve.add_point(Map.laser_a, Vector2.ZERO, Vector2(0,0))
	curve.add_point(Map.laser_b, Vector2(0,0), Vector2.ZERO)
	line_2d.points = curve.get_baked_points()

	for i in 10:
		line_2d.set_width(1)	
		line_2d.set_default_color(Color.ORANGE)	
		await get_tree().create_timer(0.05).timeout
		line_2d.set_width(2)
		line_2d.set_default_color(Color.WHITE)
		await get_tree().create_timer(0.05).timeout
		
	line_2d.hide()	
	get_node("../TileMap").hovertile.show()
