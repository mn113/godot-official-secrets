extends Node3D


var player_ref
var area_node
var label_node
var is_player_adjacent


func _ready():
	player_ref = get_tree().get_nodes_in_group("player")[0]
	area_node = %Outbox_Area3D
	label_node = %Outbox_Label3D
	label_node.hide()


func _process(_delta):
	if is_player_adjacent:
		label_node.show()
	else:
		label_node.hide()


# connected from Area3D node in Godot UI
func _on_body_entered(body):
	if body.is_in_group("player"):
		is_player_adjacent = true


# connected from Area3D node in Godot UI
func _on_body_exited(body):
	if body.is_in_group("player"):
		is_player_adjacent = false


func _input(event):
	if event.is_action_pressed("interact"):
		if (is_player_adjacent):
			interact()


func interact():
	PubSub.outbox_interact.emit()
