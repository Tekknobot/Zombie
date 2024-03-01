extends Node2D

@export var Map: TileMap

var point1 : Vector2 = Vector2(0, 0)
var width : int = 2
var color : Color = Color.RED
@export var antialiasing : bool = true

@onready var line_2d = $"../Line2D"

var _point2 : Vector2

func _process(_delta):
	pass

func draw_laser():
	line_2d.set_joint_mode(2)
	var curve := Curve2D.new()
	curve.add_point(Map.laser_a, Vector2.ZERO, Vector2(0,0))
	curve.add_point(Map.laser_b, Vector2(0,0), Vector2.ZERO)
	line_2d.points = curve.get_baked_points()
