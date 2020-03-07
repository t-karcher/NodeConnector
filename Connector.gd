tool
extends Node2D

class_name Connector

enum ConnectorType {STRAIGHT, CURVED, ELBOW}

var node_from: Sprite = null
var node_to: Sprite = null
var curve: Curve2D = Curve2D.new()

export (ConnectorType) var connector_type = ConnectorType.STRAIGHT setget update_connector_type
export (float, -50, 50) var displacement = 0 setget update_displacement

func update_displacement(new_value):
	displacement = new_value
	draw_connector()

func update_connector_type(new_value):
	connector_type = new_value
	draw_connector()

func _ready():
	update_connected_nodes()

func _get_configuration_warning():
	if get_child_count() != 2:
		return "Needs two Sprite subnodes to create a connection"
	else:
		return ""

func add_child(node, uln=false):
	.add_child(node, uln)
	update_connected_nodes()

func remove_child(node):
	.remove_child(node)
	update_connected_nodes()
		
func update_connected_nodes():
	if get_child_count() == 2:
		node_from = get_child(0)
		node_to = get_child(1)
		if !node_from.is_connected("item_rect_changed", self, "draw_connector"):
			# warning-ignore:return_value_discarded
			node_from.connect("item_rect_changed", self, "draw_connector")
		if !node_to.is_connected("item_rect_changed", self, "draw_connector"):
			# warning-ignore:return_value_discarded
			node_to.connect("item_rect_changed", self, "draw_connector")
	else:
		node_from = null
		node_to = null
	draw_connector()
	

func draw_connector():
	curve.clear_points()
	if is_instance_valid(node_from) && is_instance_valid(node_to):
		node_from.update()
		node_to.update()
		var angle = node_from.get_angle_to(node_to.position)
		var distance = node_from.position.distance_to(node_to.position)
		var direction: Vector2
		if (angle >= PI * 1/4) && (angle < PI * 3/4): direction = Vector2.UP
		elif (angle <= -PI * 1/4) && (angle > -PI * 3/4): direction = Vector2.DOWN
		elif (angle < PI * 1/4) && (angle > -PI * 1/4): direction = Vector2.LEFT
		else: direction = Vector2.RIGHT
		match connector_type:
			ConnectorType.STRAIGHT:
				curve.add_point(node_from.position)
				curve.add_point(node_to.position)
			ConnectorType.CURVED:
				curve.add_point(node_from.position,Vector2.ZERO, direction * distance * (displacement - 50) / 100)
				curve.add_point(node_to.position, direction * distance * (displacement + 50) / 100)
			ConnectorType.ELBOW:
				curve.add_point(node_from.position)
				if (direction == Vector2.LEFT || direction == Vector2.RIGHT):
					curve.add_point(Vector2(
						node_from.position.x + (node_to.position.x - node_from.position.x) * (displacement + 50) / 100,
						node_from.position.y))
					curve.add_point(Vector2(
						node_from.position.x + (node_to.position.x - node_from.position.x) * (displacement + 50) / 100,
						node_to.position.y))
				else:
					curve.add_point(Vector2(
						node_from.position.x,
						node_from.position.y + (node_to.position.y - node_from.position.y) * (displacement + 50) / 100))
					curve.add_point(Vector2(
						node_to.position.x,
						node_from.position.y + (node_to.position.y - node_from.position.y) * (displacement + 50) / 100))
				curve.add_point(node_to.position)
		self.update()

func _draw():
	for i in range(curve.get_baked_points().size() - 1):
		draw_line(curve.get_baked_points()[i],curve.get_baked_points()[i+1],Color("ff0000"),5)

